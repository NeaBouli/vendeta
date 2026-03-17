// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVendRegistry.sol";

/// @title VendTrust
/// @notice Community voting + Trust Score for Vendetta
/// @dev Trust 0-1000 (default 500, min 100)
///      Weighted votes: weight = voter_trust
///      Locality Lock: voter in region within 7 days
///      Rate limit: max 3 neg votes A->B per 30 days
contract VendTrust is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard
{
    // ─────────────────────────────────────────
    // CONSTANTS
    // ─────────────────────────────────────────
    uint16 public constant DEFAULT_TRUST   = 500;
    uint16 public constant MAX_TRUST       = 1000;
    uint16 public constant MIN_TRUST       = 100;
    uint16 public constant TRUST_GAIN_VOTE = 2;
    uint16 public constant TRUST_GAIN_SUB  = 5;
    uint16 public constant TRUST_LOSS_LIAR = 50;
    uint16 public constant TRUST_RECOVERY  = 1;
    uint8  public constant MIN_VOTES_CONSENSUS = 3;
    uint8  public constant MAX_NEG_VOTES_PAIR  = 3;
    uint32 public constant NEG_VOTE_WINDOW = 30 days;
    uint32 public constant LOCALITY_WINDOW = 7 days;
    uint16 public constant CONSENSUS_VERIFY_BPS  = 8000;  // 80%
    uint16 public constant CONSENSUS_DISPUTE_BPS = 7500;  // 75%

    // ─────────────────────────────────────────
    // STORAGE
    // ─────────────────────────────────────────

    /// Trust score per user (0 = unset, defaults to 500)
    mapping(bytes32 => uint16) public trustScore;

    /// Last day trust recovery was claimed
    mapping(bytes32 => uint32) public lastCleanDay;

    /// Votes per submission: voter_hash => 0=none, 1=up, 2=down
    mapping(bytes32 => mapping(bytes32 => uint8)) public votes;

    /// Weighted vote tallies per submission
    mapping(bytes32 => uint32) public weightedUpvotes;
    mapping(bytes32 => uint32) public weightedDownvotes;
    mapping(bytes32 => uint16) public totalVoters;

    /// Neg vote rate limit: voter => target => window => count
    mapping(bytes32 => mapping(bytes32 =>
        mapping(uint32 => uint8))) public negVoteCount;

    /// Locality proof: user => geohash5 => last timestamp
    mapping(bytes32 => mapping(string => uint32))
        public userRegionLastSeen;

    /// Stats
    mapping(bytes32 => uint32) public totalVotesCast;
    uint256 public totalVotesGlobal;

    /// Registry reference
    IVendRegistry public registry;

    // ─────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────
    event VoteCast(
        bytes32 indexed submission_hash,
        bytes32 indexed voter_hash,
        bool    upvote,
        uint16  voter_trust,
        uint32  weighted_up,
        uint32  weighted_down
    );

    event ConsensusReached(
        bytes32 indexed submission_hash,
        bool    verified,
        uint32  weighted_up,
        uint32  weighted_down
    );

    event TrustUpdated(
        bytes32 indexed user_hash,
        uint16  old_trust,
        uint16  new_trust,
        string  reason
    );

    event LocalityRecorded(
        bytes32 indexed user_hash,
        string  geohash5,
        uint32  timestamp
    );

    // ─────────────────────────────────────────
    // ERRORS
    // ─────────────────────────────────────────
    error AlreadyVoted(bytes32 sub, bytes32 voter);
    error SubmissionNotFound(bytes32 hash);
    error SelfVoteNotAllowed();
    error LocalityCheckFailed(bytes32 voter, string geo);
    error NegVoteRateLimitExceeded(bytes32 voter, bytes32 target);
    error InvalidVoterHash();
    error SubmissionFinalized(bytes32 hash);

    // ─────────────────────────────────────────
    // INITIALIZER
    // ─────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address initialOwner,
        address registryAddress
    ) public initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();
        registry = IVendRegistry(registryAddress);
    }

    // ─────────────────────────────────────────
    // CORE: VOTE
    // ─────────────────────────────────────────

    /// @notice Cast a vote on a submission
    /// @param submission_hash The submission to vote on
    /// @param voter_hash The voter's nullifier-derived identity
    /// @param upvote True = confirm, False = dispute
    function vote(
        bytes32 submission_hash,
        bytes32 voter_hash,
        bool    upvote
    ) external whenNotPaused nonReentrant {
        // ── CHECKS ──────────────────────────
        if (voter_hash == bytes32(0)) revert InvalidVoterHash();

        IVendRegistry.Submission memory sub =
            registry.getSubmission(submission_hash);
        if (sub.timestamp == 0)
            revert SubmissionNotFound(submission_hash);
        if (sub.status >= 2)
            revert SubmissionFinalized(submission_hash);
        if (voter_hash == sub.user_hash)
            revert SelfVoteNotAllowed();
        if (votes[submission_hash][voter_hash] != 0)
            revert AlreadyVoted(submission_hash, voter_hash);

        // Locality Lock: voter must have been in region
        if (!_inRegion(voter_hash, sub.geohash5))
            revert LocalityCheckFailed(voter_hash, sub.geohash5);

        // Neg vote rate limit
        if (!upvote) {
            uint32 wk = uint32(block.timestamp / NEG_VOTE_WINDOW);
            if (negVoteCount[voter_hash][sub.user_hash][wk]
                >= MAX_NEG_VOTES_PAIR)
                revert NegVoteRateLimitExceeded(
                    voter_hash, sub.user_hash);
        }

        // ── EFFECTS ─────────────────────────
        uint16 vt = _trust(voter_hash);
        uint32 w  = uint32(vt);

        votes[submission_hash][voter_hash] = upvote ? 1 : 2;

        if (upvote) {
            weightedUpvotes[submission_hash] += w;
        } else {
            weightedDownvotes[submission_hash] += w;
            uint32 wk = uint32(block.timestamp / NEG_VOTE_WINDOW);
            negVoteCount[voter_hash][sub.user_hash][wk]++;
        }

        totalVoters[submission_hash]++;
        totalVotesCast[voter_hash]++;
        totalVotesGlobal++;

        // Voter gains trust for participating
        _adjust(voter_hash, int16(uint16(TRUST_GAIN_VOTE)),
            "vote_participation");

        // Check consensus if enough voters
        if (totalVoters[submission_hash] >= MIN_VOTES_CONSENSUS)
            _checkConsensus(submission_hash, sub.user_hash);

        // ── INTERACTIONS ────────────────────
        emit VoteCast(
            submission_hash, voter_hash, upvote, vt,
            weightedUpvotes[submission_hash],
            weightedDownvotes[submission_hash]
        );
    }

    // ─────────────────────────────────────────
    // LOCALITY PROOF
    // ─────────────────────────────────────────

    /// @notice Record that a user was seen in a geohash region
    /// @dev Called by app when user submits or is in region
    function recordRegionVisit(
        bytes32 user_hash,
        string calldata geohash5
    ) external whenNotPaused {
        if (user_hash == bytes32(0)) revert InvalidVoterHash();
        userRegionLastSeen[user_hash][geohash5] =
            uint32(block.timestamp);
        emit LocalityRecorded(
            user_hash, geohash5, uint32(block.timestamp)
        );
    }

    // ─────────────────────────────────────────
    // TRUST RECOVERY (+1/day)
    // ─────────────────────────────────────────

    /// @notice Recover trust over time (+1 per clean day)
    function recoverTrust(bytes32 user_hash)
        external whenNotPaused
    {
        uint32 today = uint32(block.timestamp / 1 days);
        uint32 last  = lastCleanDay[user_hash];
        if (last == 0) {
            lastCleanDay[user_hash] = today;
            return;
        }
        uint32 days_ = today - last;
        if (days_ == 0) return;
        // Cap at 100 days max recovery per call
        uint16 gain = uint16(days_ > 100 ? 100 : days_)
            * TRUST_RECOVERY;
        _adjust(user_hash, int16(uint16(gain)), "daily_recovery");
        lastCleanDay[user_hash] = today;
    }

    // ─────────────────────────────────────────
    // VIEW FUNCTIONS
    // ─────────────────────────────────────────

    function getTrust(bytes32 u) external view returns (uint16) {
        return _trust(u);
    }

    function getRewardMultiplier(bytes32 u)
        external view returns (uint256 num, uint256 den)
    {
        return (_trust(u), 1000);
    }

    function hasVoted(bytes32 sub, bytes32 voter)
        external view returns (bool)
    {
        return votes[sub][voter] != 0;
    }

    function getVoteStatus(bytes32 sub)
        external view
        returns (uint32 up, uint32 down,
                 uint16 voters, bool consensus)
    {
        return (
            weightedUpvotes[sub],
            weightedDownvotes[sub],
            totalVoters[sub],
            totalVoters[sub] >= MIN_VOTES_CONSENSUS
        );
    }

    // ─────────────────────────────────────────
    // ADMIN
    // ─────────────────────────────────────────

    function setRegistry(address r) external onlyOwner {
        registry = IVendRegistry(r);
    }

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function _authorizeUpgrade(address)
        internal override onlyOwner {}

    // ─────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────

    /// @dev Returns trust, defaulting to 500 if unset
    function _trust(bytes32 u) internal view returns (uint16) {
        uint16 t = trustScore[u];
        return t == 0 ? DEFAULT_TRUST : t;
    }

    /// @dev Adjust trust within [MIN_TRUST, MAX_TRUST]
    function _adjust(
        bytes32 u, int16 d, string memory r
    ) internal {
        uint16 old = _trust(u);
        int32  raw = int32(uint32(old)) + int32(d);
        uint16 nw;
        if (raw <= int32(uint32(MIN_TRUST))) nw = MIN_TRUST;
        else if (raw >= int32(uint32(MAX_TRUST))) nw = MAX_TRUST;
        else nw = uint16(uint32(raw));
        if (nw != old) {
            trustScore[u] = nw;
            emit TrustUpdated(u, old, nw, r);
        }
    }

    /// @dev Check if user was in geohash region within 7 days
    function _inRegion(
        bytes32 u, string memory geo
    ) internal view returns (bool) {
        uint32 last = userRegionLastSeen[u][geo];
        if (last == 0) return false;
        return (block.timestamp - last) <= LOCALITY_WINDOW;
    }

    /// @dev Check if consensus is reached (80% verify / 75% dispute)
    function _checkConsensus(
        bytes32 sub, bytes32 submitter
    ) internal {
        uint32 up   = weightedUpvotes[sub];
        uint32 down = weightedDownvotes[sub];
        uint32 tot  = up + down;
        if (tot == 0) return;

        uint32 upBps   = (up   * 10000) / tot;
        uint32 downBps = (down * 10000) / tot;

        if (upBps >= CONSENSUS_VERIFY_BPS) {
            _adjust(submitter, int16(uint16(TRUST_GAIN_SUB)),
                "submission_verified");
            emit ConsensusReached(sub, true, up, down);
        } else if (downBps >= CONSENSUS_DISPUTE_BPS) {
            _adjust(submitter, -int16(uint16(TRUST_LOSS_LIAR)),
                "submission_disputed");
            emit ConsensusReached(sub, false, up, down);
        }
    }
}
