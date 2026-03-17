// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVendRewards.sol";

/// @title VendClaim
/// @notice Credits -> IFR conversion gateway for Vendetta
///
/// @dev Phase 1 Architecture (Event-based):
///   User calls claim() on Base L2
///   -> Credits deducted from VendRewards
///   -> ClaimInitiated event emitted
///   -> Off-chain backend reads event
///   -> Backend transfers IFR from PartnerVault
///      on ETH Mainnet to user wallet
///
/// Phase 3 (Bridge):
///   LayerZero or native Base bridge
///   fully on-chain cross-chain transfer
///
/// IFR decimals: 9 (NOT 18!)
/// Minimum claim: 1,000 credits
/// Conversion rate: dynamic (set by owner)
contract VendClaim is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard
{
    // ─────────────────────────────────────────
    // CONSTANTS
    // ─────────────────────────────────────────

    /// IFR has 9 decimals (not 18!)
    uint8  public constant IFR_DECIMALS = 9;

    /// Minimum credits required to claim
    uint256 public constant MIN_CLAIM_CREDITS = 1_000;

    /// Anti-spam: minimum seconds between claims per user
    uint32 public constant CLAIM_COOLDOWN = 7 days;

    // ─────────────────────────────────────────
    // STORAGE
    // ─────────────────────────────────────────

    /// VendRewards contract reference
    IVendRewards public rewardsContract;

    /// Conversion rate: credits per 1 IFR unit (9 decimals)
    /// Example: rate = 10_000 means 10,000 credits = 1 IFR
    uint256 public creditsPerIfrUnit;

    /// Total IFR claimed (in IFR base units, 9 decimals)
    uint256 public totalIfrClaimed;

    /// Total claims processed
    uint256 public totalClaimsCount;

    /// Last claim timestamp per user_hash
    mapping(bytes32 => uint32) public lastClaimAt;

    /// Total credits claimed per user (historical)
    mapping(bytes32 => uint256) public totalCreditsClaimed;

    /// ETH Mainnet wallet address per user_hash
    mapping(bytes32 => address) public mainnetWallet;

    /// Claim nonce per user (replay protection)
    mapping(bytes32 => uint256) public claimNonce;

    // ─────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────

    /// @notice Emitted when a claim is initiated.
    /// Off-chain backend listens and processes IFR transfer.
    event ClaimInitiated(
        bytes32 indexed user_hash,
        address indexed mainnet_wallet,
        uint256 credits_burned,
        uint256 ifr_amount,
        uint256 nonce,
        uint32  timestamp
    );

    event WalletRegistered(
        bytes32 indexed user_hash,
        address indexed mainnet_wallet
    );

    event RateUpdated(
        uint256 old_rate,
        uint256 new_rate,
        uint32  timestamp
    );

    // ─────────────────────────────────────────
    // ERRORS
    // ─────────────────────────────────────────

    error InsufficientCredits(
        bytes32 user_hash, uint256 balance, uint256 required);
    error CooldownNotElapsed(
        bytes32 user_hash, uint32 available_at);
    error NoMainnetWallet(bytes32 user_hash);
    error InvalidWalletAddress();
    error InvalidConversionRate();
    error InvalidUserHash();
    error AmountTooLow(uint256 amount, uint256 minimum);
    error ZeroIfrAmount();

    // ─────────────────────────────────────────
    // INITIALIZER
    // ─────────────────────────────────────────

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address initialOwner,
        address rewardsAddress,
        uint256 initialRate
    ) public initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();
        rewardsContract   = IVendRewards(rewardsAddress);
        creditsPerIfrUnit = initialRate;
    }

    // ─────────────────────────────────────────
    // WALLET REGISTRATION
    // ─────────────────────────────────────────

    /// @notice Register an ETH Mainnet wallet for IFR delivery
    function registerWallet(
        bytes32 user_hash,
        address wallet_address
    ) external whenNotPaused {
        if (user_hash == bytes32(0)) revert InvalidUserHash();
        if (wallet_address == address(0))
            revert InvalidWalletAddress();

        mainnetWallet[user_hash] = wallet_address;
        emit WalletRegistered(user_hash, wallet_address);
    }

    // ─────────────────────────────────────────
    // CLAIM
    // ─────────────────────────────────────────

    /// @notice Claim IFR for accumulated credits
    /// @param user_hash Nullifier-derived user identity
    /// @param credits_amount Amount of credits to claim (>= 1000)
    function claim(
        bytes32 user_hash,
        uint256 credits_amount
    )
        external
        whenNotPaused
        nonReentrant
    {
        // ── CHECKS ──────────────────────────

        if (user_hash == bytes32(0))
            revert InvalidUserHash();

        if (credits_amount < MIN_CLAIM_CREDITS)
            revert AmountTooLow(
                credits_amount, MIN_CLAIM_CREDITS);

        address wallet = mainnetWallet[user_hash];
        if (wallet == address(0))
            revert NoMainnetWallet(user_hash);

        // Cooldown check
        uint32 lastClaim = lastClaimAt[user_hash];
        if (lastClaim > 0) {
            uint32 availableAt = lastClaim + CLAIM_COOLDOWN;
            if (uint32(block.timestamp) < availableAt)
                revert CooldownNotElapsed(
                    user_hash, availableAt);
        }

        // Balance check
        uint256 balance =
            rewardsContract.getCredits(user_hash);
        if (balance < credits_amount)
            revert InsufficientCredits(
                user_hash, balance, credits_amount);

        // Calculate IFR amount
        uint256 ifrAmount =
            (credits_amount * (10 ** IFR_DECIMALS))
            / creditsPerIfrUnit;
        if (ifrAmount == 0) revert ZeroIfrAmount();

        // ── EFFECTS (CEI) ───────────────────

        lastClaimAt[user_hash]         = uint32(block.timestamp);
        totalCreditsClaimed[user_hash] += credits_amount;
        totalIfrClaimed                += ifrAmount;
        totalClaimsCount++;

        uint256 nonce = claimNonce[user_hash]++;

        // ── INTERACTIONS ────────────────────

        rewardsContract.deductCredits(
            user_hash, credits_amount);

        emit ClaimInitiated(
            user_hash,
            wallet,
            credits_amount,
            ifrAmount,
            nonce,
            uint32(block.timestamp)
        );
    }

    // ─────────────────────────────────────────
    // VIEW FUNCTIONS
    // ─────────────────────────────────────────

    function previewClaim(uint256 credits_amount)
        external view returns (uint256 ifr_amount)
    {
        if (creditsPerIfrUnit == 0) return 0;
        return (credits_amount * (10 ** IFR_DECIMALS))
               / creditsPerIfrUnit;
    }

    function canClaim(bytes32 user_hash)
        external view
        returns (bool ready, string memory reason)
    {
        if (mainnetWallet[user_hash] == address(0))
            return (false, "No wallet registered");

        uint256 bal = rewardsContract.getCredits(user_hash);
        if (bal < MIN_CLAIM_CREDITS)
            return (false, "Insufficient credits");

        uint32 last = lastClaimAt[user_hash];
        if (last > 0 &&
            uint32(block.timestamp) < last + CLAIM_COOLDOWN)
            return (false, "Cooldown active");

        return (true, "Ready to claim");
    }

    function getClaimStatus(bytes32 user_hash)
        external view
        returns (
            uint256 credits_balance,
            uint256 ifr_preview,
            uint32  next_claim_at,
            bool    wallet_registered,
            uint256 total_claimed_credits
        )
    {
        credits_balance   = rewardsContract.getCredits(user_hash);
        ifr_preview       = this.previewClaim(credits_balance);
        next_claim_at     = lastClaimAt[user_hash] + CLAIM_COOLDOWN;
        wallet_registered = mainnetWallet[user_hash] != address(0);
        total_claimed_credits = totalCreditsClaimed[user_hash];
    }

    // ─────────────────────────────────────────
    // ADMIN
    // ─────────────────────────────────────────

    function setConversionRate(uint256 new_rate)
        external onlyOwner
    {
        if (new_rate == 0) revert InvalidConversionRate();
        uint256 old = creditsPerIfrUnit;
        creditsPerIfrUnit = new_rate;
        emit RateUpdated(old, new_rate, uint32(block.timestamp));
    }

    function setRewardsContract(address r)
        external onlyOwner
    {
        rewardsContract = IVendRewards(r);
    }

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function _authorizeUpgrade(address)
        internal override onlyOwner {}
}
