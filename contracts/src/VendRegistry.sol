// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title VendRegistry
/// @notice Core submission registry for Vendetta
///         Stores price submissions with GPS, EAN, currency
///         Handles duplicate detection and first-mover logic
/// @dev UUPS Upgradeable, Pausable, ReentrancyGuard
///      Base L2 deployment
contract VendRegistry is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard
{
    // ─────────────────────────────────────────────────────
    // STRUCTS
    // ─────────────────────────────────────────────────────

    struct Submission {
        bytes32 ean_hash;       // keccak256(ean_string)
        uint64  price_cents;    // price in smallest currency unit
        bytes3  currency;       // ISO 4217: "EUR", "GBP", "CHF"
        int32   lat6;           // latitude  × 1e6 (use .round()!)
        int32   lng6;           // longitude × 1e6 (use .round()!)
        string  geohash5;       // precision-5 geohash for The Graph
        bytes32 user_hash;      // nullifier-derived user identifier
        uint32  timestamp;      // unix timestamp
        bool    is_first_mover; // first submission for this EAN+location
        uint8   status;         // 0=pending 1=auto_verified 2=community_verified 3=disputed
        uint32  votes_up;       // weighted upvotes (trust/1000 summed)
        uint32  votes_down;     // weighted downvotes
        uint32  auto_verify_at; // timestamp when silent consensus fires
    }

    // ─────────────────────────────────────────────────────
    // STORAGE
    // ─────────────────────────────────────────────────────

    /// All submissions by their proof hash
    mapping(bytes32 => Submission) public submissions;

    /// Hash existence check (gas-efficient boolean)
    mapping(bytes32 => bool) public hashExists;

    /// EAN+Location → first submission hash
    /// key = keccak256(ean_hash, lat6_rounded, lng6_rounded)
    mapping(bytes32 => bytes32) public firstMoverByLocation;

    /// Rate limiting: user_hash → day_key → count
    /// day_key = timestamp / 86400
    mapping(bytes32 => mapping(uint32 => uint8)) public dailySubmissions;

    /// Max submissions per user per location per day
    uint8 public constant MAX_DAILY_SUBMISSIONS = 10;

    /// Silent consensus window: 72 hours
    uint32 public constant SILENT_CONSENSUS_SECONDS = 72 hours;

    /// Location precision for first-mover check (~150m grid)
    /// lat6 and lng6 are snapped to nearest 150000 units
    int32 public constant LOCATION_SNAP = 150000; // 0.15 degrees ≈ 150m

    /// Total submission count (for stats)
    uint256 public totalSubmissions;

    // ─────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────

    event SubmissionCreated(
        bytes32 indexed hash,
        bytes32 indexed ean_hash,
        uint64  price_cents,
        bytes3  currency,
        int32   lat6,
        int32   lng6,
        string  geohash5,
        bytes32 indexed user_hash,
        bool    is_first_mover,
        uint32  timestamp
    );

    event DuplicateDetected(
        bytes32 indexed existing_hash,
        bytes32 indexed new_hash,
        bytes32 indexed user_hash
    );

    event SubmissionAutoVerified(
        bytes32 indexed hash,
        bytes32 indexed user_hash
    );

    // ─────────────────────────────────────────────────────
    // ERRORS
    // ─────────────────────────────────────────────────────

    error HashAlreadyExists(bytes32 hash);
    error RateLimitExceeded(bytes32 user_hash, uint32 day);
    error InvalidCoordinates(int32 lat6, int32 lng6);
    error InvalidCurrency(bytes3 currency);
    error InvalidPrice();
    error InvalidEanHash();
    error InvalidUserHash();

    // ─────────────────────────────────────────────────────
    // INITIALIZER (replaces constructor for upgradeable)
    // ─────────────────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();
    }

    // ─────────────────────────────────────────────────────
    // CORE FUNCTION: SUBMIT
    // ─────────────────────────────────────────────────────

    /// @notice Submit a price observation to the registry
    /// @param hash         SHA-256 proof hash (generated client-side via Rust FFI)
    /// @param ean_hash     keccak256 of EAN string
    /// @param price_cents  Price in smallest currency unit
    /// @param currency     ISO 4217 bytes3 ("EUR", "GBP", "CHF")
    /// @param lat6         Latitude  × 1e6, rounded (NOT truncated)
    /// @param lng6         Longitude × 1e6, rounded (NOT truncated)
    /// @param geohash5     Precision-5 geohash string
    /// @param user_hash    Nullifier-derived user identifier
    function submit(
        bytes32 hash,
        bytes32 ean_hash,
        uint64  price_cents,
        bytes3  currency,
        int32   lat6,
        int32   lng6,
        string  calldata geohash5,
        bytes32 user_hash
    )
        external
        whenNotPaused
        nonReentrant
    {
        // ── CHECKS ──────────────────────────────────────

        // Input validation
        if (hash == bytes32(0)) revert InvalidEanHash();
        if (ean_hash == bytes32(0)) revert InvalidEanHash();
        if (user_hash == bytes32(0)) revert InvalidUserHash();
        if (price_cents == 0) revert InvalidPrice();
        if (!_validCurrency(currency)) revert InvalidCurrency(currency);
        if (!_validCoordinates(lat6, lng6))
            revert InvalidCoordinates(lat6, lng6);

        // Duplicate hash check
        if (hashExists[hash]) revert HashAlreadyExists(hash);

        // Rate limit: max 10 per user per day
        uint32 dayKey = uint32(block.timestamp / 86400);
        if (dailySubmissions[user_hash][dayKey] >=
            MAX_DAILY_SUBMISSIONS) {
            revert RateLimitExceeded(user_hash, dayKey);
        }

        // ── EFFECTS ─────────────────────────────────────

        // Mark hash as existing (before any state changes)
        hashExists[hash] = true;

        // Rate limit increment
        dailySubmissions[user_hash][dayKey]++;

        // First-mover check using snapped location grid
        bytes32 locationKey = _locationKey(ean_hash, lat6, lng6);
        bool isFirstMover = (firstMoverByLocation[locationKey]
            == bytes32(0));
        if (isFirstMover) {
            firstMoverByLocation[locationKey] = hash;
        } else {
            // Emit duplicate event for reward decay calculation
            emit DuplicateDetected(
                firstMoverByLocation[locationKey],
                hash,
                user_hash
            );
        }

        // Silent consensus: auto-verify after 72h
        uint32 autoVerifyAt = uint32(block.timestamp)
            + SILENT_CONSENSUS_SECONDS;

        // Store submission (AFTER all checks)
        submissions[hash] = Submission({
            ean_hash:       ean_hash,
            price_cents:    price_cents,
            currency:       currency,
            lat6:           lat6,
            lng6:           lng6,
            geohash5:       geohash5,
            user_hash:      user_hash,
            timestamp:      uint32(block.timestamp),
            is_first_mover: isFirstMover,
            status:         0, // pending
            votes_up:       0,
            votes_down:     0,
            auto_verify_at: autoVerifyAt
        });

        totalSubmissions++;

        // ── INTERACTIONS (events last) ───────────────────
        emit SubmissionCreated(
            hash,
            ean_hash,
            price_cents,
            currency,
            lat6,
            lng6,
            geohash5,
            user_hash,
            isFirstMover,
            uint32(block.timestamp)
        );
    }

    // ─────────────────────────────────────────────────────
    // SILENT CONSENSUS: auto-verify after 72h
    // ─────────────────────────────────────────────────────

    /// @notice Trigger silent consensus for a submission
    ///         Anyone can call this after 72h with no downvotes
    ///         VendRewards will listen to the event
    function triggerSilentConsensus(bytes32 hash)
        external
        whenNotPaused
    {
        Submission storage s = submissions[hash];
        require(s.timestamp > 0, "Submission not found");
        require(s.status == 0, "Not pending");
        require(block.timestamp >= s.auto_verify_at,
            "72h not elapsed");
        require(s.votes_down == 0, "Has downvotes");

        // EFFECTS before INTERACTIONS
        s.status = 1; // auto_verified

        emit SubmissionAutoVerified(hash, s.user_hash);
    }

    // ─────────────────────────────────────────────────────
    // VIEW FUNCTIONS
    // ─────────────────────────────────────────────────────

    function getSubmission(bytes32 hash)
        external view
        returns (Submission memory)
    {
        return submissions[hash];
    }

    function isFirstMoverFor(
        bytes32 ean_hash,
        int32 lat6,
        int32 lng6
    ) external view returns (bool) {
        bytes32 key = _locationKey(ean_hash, lat6, lng6);
        return firstMoverByLocation[key] == bytes32(0);
    }

    // ─────────────────────────────────────────────────────
    // INTERNAL HELPERS
    // ─────────────────────────────────────────────────────

    /// Snap coordinates to ~150m grid for first-mover check
    function _locationKey(
        bytes32 ean_hash,
        int32 lat6,
        int32 lng6
    ) internal pure returns (bytes32) {
        int32 snapped_lat = (lat6 / LOCATION_SNAP) * LOCATION_SNAP;
        int32 snapped_lng = (lng6 / LOCATION_SNAP) * LOCATION_SNAP;
        return keccak256(abi.encodePacked(
            ean_hash, snapped_lat, snapped_lng
        ));
    }

    function _validCoordinates(int32 lat6, int32 lng6)
        internal pure returns (bool)
    {
        return lat6 >= -90_000_000 && lat6 <= 90_000_000
            && lng6 >= -180_000_000 && lng6 <= 180_000_000;
    }

    function _validCurrency(bytes3 currency)
        internal pure returns (bool)
    {
        return currency == "EUR" || currency == "GBP"
            || currency == "CHF" || currency == "PLN"
            || currency == "CZK" || currency == "HUF"
            || currency == "RON" || currency == "SEK"
            || currency == "NOK" || currency == "DKK";
    }

    // ─────────────────────────────────────────────────────
    // ADMIN
    // ─────────────────────────────────────────────────────

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /// Required by UUPS — only owner can upgrade
    function _authorizeUpgrade(address newImplementation)
        internal override onlyOwner {}
}
