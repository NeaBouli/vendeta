// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVendRegistry.sol";
import "./interfaces/IVendTrust.sol";

/// @title VendRewards
/// @notice Credit system for Vendetta
/// @dev Calculates and stores IFR credits earned by users.
///      formula: reward = BASE * trust_mult * bonus / dup_count
///      First-Mover: 2x — paid after first confirmation (not instant)
///      Silent Consensus: auto-verified after 72h = 0.7x multiplier
///      IFR Premium: isLocked check → +20% bonus (Phase 3, flag for now)
///      Minimum claim: 1000 credits
contract VendRewards is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard
{
    // ─────────────────────────────────────────
    // CONSTANTS
    // ─────────────────────────────────────────

    uint64 public constant BASE_REWARD          = 100;
    uint64 public constant MIN_CLAIM            = 1000;

    /// First mover bonus numerator (2x = 2000/1000)
    uint32 public constant FIRST_MOVER_BPS      = 2000;
    /// Silent consensus multiplier (0.7x = 700/1000)
    uint32 public constant SILENT_CONSENSUS_BPS = 700;
    /// IFR Premium bonus (+20% = 200/1000 extra)
    uint32 public constant IFR_PREMIUM_BPS      = 200;
    /// Basis points denominator
    uint32 public constant BPS_DENOM            = 1000;

    // ─────────────────────────────────────────
    // STORAGE
    // ─────────────────────────────────────────

    /// Credits earned per user_hash
    mapping(bytes32 => uint256) public credits;

    /// Total credits ever earned (stats)
    uint256 public totalCreditsEarned;

    /// Tracks which submissions have already paid first-mover bonus
    mapping(bytes32 => bool) public firstMoverPaid;

    /// Tracks which submissions have triggered silent consensus reward
    mapping(bytes32 => bool) public silentConsensusPaid;

    /// Duplicate count per EAN+location (for decay calculation)
    mapping(bytes32 => uint32) public dupCount;

    /// IFR Premium flag per user (Phase 3: replaced by on-chain check)
    mapping(bytes32 => bool) public ifrPremium;

    /// Contract references
    IVendRegistry public registry;
    IVendTrust    public trustContract;

    /// Authorized claimer address (VendClaim contract)
    address public authorizedClaimer;

    // ─────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────

    event RewardEarned(
        bytes32 indexed user_hash,
        bytes32 indexed submission_hash,
        uint64  base_reward,
        uint64  final_reward,
        string  reward_type
    );

    event CreditsUpdated(
        bytes32 indexed user_hash,
        uint256 old_balance,
        uint256 new_balance
    );

    event FirstMoverBonusPaid(
        bytes32 indexed submission_hash,
        bytes32 indexed user_hash,
        uint64  bonus_credits
    );

    event SilentConsensusPaid(
        bytes32 indexed submission_hash,
        bytes32 indexed user_hash,
        uint64  credits_paid
    );

    // ─────────────────────────────────────────
    // ERRORS
    // ─────────────────────────────────────────

    error InsufficientCredits(
        bytes32 user_hash, uint256 balance, uint256 required);
    error SubmissionNotFound(bytes32 hash);
    error AlreadyPaid(bytes32 submission_hash, string reward_type);
    error InvalidUserHash();
    error InvalidSubmissionHash();
    error ZeroReward();

    // ─────────────────────────────────────────
    // INITIALIZER
    // ─────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address initialOwner,
        address registryAddress,
        address trustAddress
    ) public initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();
        registry      = IVendRegistry(registryAddress);
        trustContract = IVendTrust(trustAddress);
    }

    // ─────────────────────────────────────────
    // REWARD ON SUBMISSION
    // ─────────────────────────────────────────

    /// @notice Grant base reward when a submission is created
    /// @param submission_hash Hash of the submission
    /// @param dup_count_at_time Duplicate count at time of submission
    function rewardSubmission(
        bytes32 submission_hash,
        uint32  dup_count_at_time
    )
        external
        whenNotPaused
        nonReentrant
    {
        // CHECKS
        if (submission_hash == bytes32(0))
            revert InvalidSubmissionHash();

        IVendRegistry.Submission memory sub =
            registry.getSubmission(submission_hash);
        if (sub.timestamp == 0)
            revert SubmissionNotFound(submission_hash);

        bytes32 user = sub.user_hash;
        if (user == bytes32(0)) revert InvalidUserHash();

        // EFFECTS
        bytes32 locKey = _locationKey(
            sub.ean_hash, sub.lat6, sub.lng6);
        if (dup_count_at_time > dupCount[locKey]) {
            dupCount[locKey] = dup_count_at_time;
        }

        uint64 reward = _calcBaseReward(user, dup_count_at_time);
        if (reward == 0) revert ZeroReward();

        _addCredits(user, reward);

        // INTERACTIONS
        emit RewardEarned(
            user, submission_hash,
            BASE_REWARD, reward, "submit"
        );
    }

    /// @notice Pay the first-mover 2x bonus (delayed, after confirmation)
    function payFirstMoverBonus(bytes32 submission_hash)
        external
        whenNotPaused
        nonReentrant
    {
        // CHECKS
        if (firstMoverPaid[submission_hash])
            revert AlreadyPaid(submission_hash, "first_mover");

        IVendRegistry.Submission memory sub =
            registry.getSubmission(submission_hash);
        if (sub.timestamp == 0)
            revert SubmissionNotFound(submission_hash);
        if (!sub.is_first_mover) return; // not first mover, skip

        bytes32 user = sub.user_hash;

        // EFFECTS — CEI: set flag before credits
        firstMoverPaid[submission_hash] = true;

        (uint256 trustNum, uint256 trustDen) =
            trustContract.getRewardMultiplier(user);
        uint64 bonus = uint64(
            (BASE_REWARD * trustNum * FIRST_MOVER_BPS)
            / (trustDen * BPS_DENOM)
        );
        if (ifrPremium[user]) {
            bonus = bonus + uint64(
                uint256(bonus) * IFR_PREMIUM_BPS / BPS_DENOM);
        }

        _addCredits(user, bonus);

        // INTERACTIONS
        emit FirstMoverBonusPaid(submission_hash, user, bonus);
        emit RewardEarned(
            user, submission_hash,
            BASE_REWARD, bonus, "first_mover"
        );
    }

    /// @notice Pay silent consensus reward (72h auto-verify, 0.7x)
    function paySilentConsensusReward(bytes32 submission_hash)
        external
        whenNotPaused
        nonReentrant
    {
        // CHECKS
        if (silentConsensusPaid[submission_hash])
            revert AlreadyPaid(submission_hash, "silent_consensus");

        IVendRegistry.Submission memory sub =
            registry.getSubmission(submission_hash);
        if (sub.timestamp == 0)
            revert SubmissionNotFound(submission_hash);
        require(sub.status == 1, "Not auto_verified");

        bytes32 user = sub.user_hash;

        // EFFECTS — CEI: set flag before credits
        silentConsensusPaid[submission_hash] = true;

        (uint256 trustNum, uint256 trustDen) =
            trustContract.getRewardMultiplier(user);

        uint32 dupC = dupCount[
            _locationKey(sub.ean_hash, sub.lat6, sub.lng6)
        ];
        if (dupC == 0) dupC = 1;

        uint64 reward = uint64(
            (BASE_REWARD * trustNum * SILENT_CONSENSUS_BPS)
            / (trustDen * BPS_DENOM * dupC)
        );

        if (ifrPremium[user]) {
            reward = reward + uint64(
                uint256(reward) * IFR_PREMIUM_BPS / BPS_DENOM);
        }

        if (reward == 0) return;

        _addCredits(user, reward);

        // INTERACTIONS
        emit SilentConsensusPaid(submission_hash, user, reward);
        emit RewardEarned(
            user, submission_hash,
            BASE_REWARD, reward, "silent"
        );
    }

    // ─────────────────────────────────────────
    // CREDIT MANAGEMENT (for VendClaim)
    // ─────────────────────────────────────────

    /// @notice Deduct credits for claim. Only callable by VendClaim.
    function deductCredits(bytes32 user_hash, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        onlyAuthorizedClaimer
    {
        if (user_hash == bytes32(0)) revert InvalidUserHash();
        if (amount < MIN_CLAIM)
            revert InsufficientCredits(
                user_hash, credits[user_hash], MIN_CLAIM);
        if (credits[user_hash] < amount)
            revert InsufficientCredits(
                user_hash, credits[user_hash], amount);

        // EFFECTS — CEI
        uint256 oldBal = credits[user_hash];
        credits[user_hash] = oldBal - amount;

        // INTERACTIONS
        emit CreditsUpdated(user_hash, oldBal, credits[user_hash]);
    }

    // ─────────────────────────────────────────
    // IFR PREMIUM (Phase 3: replace with bridge)
    // ─────────────────────────────────────────

    function setIfrPremium(bytes32 user_hash, bool premium)
        external onlyOwner
    {
        ifrPremium[user_hash] = premium;
    }

    // ─────────────────────────────────────────
    // VIEW FUNCTIONS
    // ─────────────────────────────────────────

    function getCredits(bytes32 user_hash)
        external view returns (uint256)
    {
        return credits[user_hash];
    }

    function canClaim(bytes32 user_hash)
        external view returns (bool)
    {
        return credits[user_hash] >= MIN_CLAIM;
    }

    function previewReward(
        bytes32 user_hash,
        bool    is_first_mover,
        uint32  dup_count_val,
        bool    is_silent
    ) external view returns (uint64) {
        (uint256 n, uint256 d) =
            trustContract.getRewardMultiplier(user_hash);
        uint32 dc = dup_count_val == 0 ? 1 : dup_count_val;
        uint32 bps = is_silent
            ? SILENT_CONSENSUS_BPS
            : BPS_DENOM;
        uint64 r = uint64(
            (BASE_REWARD * n * bps) / (d * BPS_DENOM * dc)
        );
        if (is_first_mover && !is_silent) {
            r += uint64(
                (BASE_REWARD * n * FIRST_MOVER_BPS)
                / (d * BPS_DENOM)
            );
        }
        if (ifrPremium[user_hash]) {
            r += uint64(uint256(r) * IFR_PREMIUM_BPS / BPS_DENOM);
        }
        return r;
    }

    // ─────────────────────────────────────────
    // ADMIN
    // ─────────────────────────────────────────

    modifier onlyAuthorizedClaimer() {
        require(
            msg.sender == authorizedClaimer
            || msg.sender == owner(),
            "Not authorized claimer"
        );
        _;
    }

    function setAuthorizedClaimer(address claimer)
        external onlyOwner
    {
        authorizedClaimer = claimer;
    }

    function setRegistry(address r) external onlyOwner {
        registry = IVendRegistry(r);
    }

    function setTrustContract(address t) external onlyOwner {
        trustContract = IVendTrust(t);
    }

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function _authorizeUpgrade(address)
        internal override onlyOwner {}

    // ─────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────

    function _addCredits(bytes32 user, uint64 amount) internal {
        uint256 old = credits[user];
        credits[user] = old + amount;
        totalCreditsEarned += amount;
        emit CreditsUpdated(user, old, credits[user]);
    }

    function _calcBaseReward(
        bytes32 user,
        uint32  dup_count_val
    ) internal view returns (uint64) {
        (uint256 n, uint256 d) =
            trustContract.getRewardMultiplier(user);
        uint32 dc = dup_count_val == 0 ? 1 : dup_count_val;
        uint64 r = uint64(
            (BASE_REWARD * n) / (d * dc)
        );
        if (ifrPremium[user]) {
            r = r + uint64(uint256(r) * IFR_PREMIUM_BPS / BPS_DENOM);
        }
        return r;
    }

    /// Same location snap as VendRegistry (~150m grid)
    int32 private constant LOCATION_SNAP = 150_000;

    function _locationKey(
        bytes32 ean_hash,
        int32   lat6,
        int32   lng6
    ) internal pure returns (bytes32) {
        int32 sl = (lat6 / LOCATION_SNAP) * LOCATION_SNAP;
        int32 sg = (lng6 / LOCATION_SNAP) * LOCATION_SNAP;
        return keccak256(abi.encodePacked(ean_hash, sl, sg));
    }
}
