// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VendClaim.sol";
import "../src/VendRewards.sol";
import "../src/VendTrust.sol";
import "../src/VendRegistry.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VendClaimTest is Test {
    VendRegistry public registry;
    VendTrust    public trust;
    VendRewards  public rewards;
    VendClaim    public vendClaim;

    bytes32 constant HASH1  = keccak256("sub1");
    bytes32 constant EAN    = keccak256("4006381333931");
    bytes32 constant USER_A = keccak256("user_a");
    bytes3  constant EUR    = "EUR";
    int32   constant LAT    = 48_137_154;
    int32   constant LNG    = 11_576_124;
    string  constant GEO    = "u281z";

    address constant WALLET_A =
        address(0x1234567890123456789012345678901234567890);

    // 10,000 credits = 1 IFR unit (9 decimals)
    uint256 constant RATE = 10_000;

    function setUp() public {
        // Deploy Registry
        VendRegistry ri = new VendRegistry();
        ERC1967Proxy rp = new ERC1967Proxy(
            address(ri),
            abi.encodeCall(VendRegistry.initialize, (address(this)))
        );
        registry = VendRegistry(address(rp));

        // Deploy Trust
        VendTrust ti = new VendTrust();
        ERC1967Proxy tp = new ERC1967Proxy(
            address(ti),
            abi.encodeCall(VendTrust.initialize,
                (address(this), address(registry)))
        );
        trust = VendTrust(address(tp));

        // Deploy Rewards
        VendRewards rwi = new VendRewards();
        ERC1967Proxy rwp = new ERC1967Proxy(
            address(rwi),
            abi.encodeCall(VendRewards.initialize,
                (address(this), address(registry), address(trust)))
        );
        rewards = VendRewards(address(rwp));

        // Deploy Claim
        VendClaim ci = new VendClaim();
        ERC1967Proxy cp = new ERC1967Proxy(
            address(ci),
            abi.encodeCall(VendClaim.initialize,
                (address(this), address(rewards), RATE))
        );
        vendClaim = VendClaim(address(cp));

        // Authorize VendClaim to deduct credits
        rewards.setAuthorizedClaimer(address(vendClaim));

        // Setup: submit + earn enough credits for testing
        // FREE tier: 100*500/1000*500/1000 = 25 credits/submission
        // Need >= 1000 for MIN_CLAIM -> 41 submissions
        // Rate limit = 10/user/day, so warp between batches
        for (uint8 i = 0; i < 41; i++) {
            if (i > 0 && i % 10 == 0) {
                vm.warp(block.timestamp + 1 days);
            }
            bytes32 h = keccak256(abi.encodePacked("sub", i));
            bytes32 e = keccak256(abi.encodePacked("ean", i));
            registry.submit(h, e, 79 + uint64(i), EUR,
                LAT, LNG, GEO, USER_A);
            rewards.rewardSubmission(h, 1);
        }
        // USER_A now has 41 * 25 = 1025 credits
    }

    function test_wallet_registration() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        assertEq(vendClaim.mainnetWallet(USER_A), WALLET_A);
    }

    function test_claim_requires_wallet() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VendClaim.NoMainnetWallet.selector, USER_A)
        );
        vendClaim.claim(USER_A, 1000);
    }

    function test_claim_success() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        uint256 before = rewards.getCredits(USER_A);
        vendClaim.claim(USER_A, 1000);
        uint256 afterBal = rewards.getCredits(USER_A);
        assertEq(afterBal, before - 1000);
    }

    function test_credits_deducted_after_claim() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        uint256 before = rewards.getCredits(USER_A);
        vendClaim.claim(USER_A, 1000);
        assertEq(rewards.getCredits(USER_A), before - 1000);
    }

    function test_cooldown_blocks_second_claim() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        vendClaim.claim(USER_A, 1000);
        // Second claim should fail (cooldown)
        vm.expectRevert();
        vendClaim.claim(USER_A, 50); // even small amount blocked
    }

    function test_cooldown_passes_after_7_days() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        vendClaim.claim(USER_A, 1000);

        // Earn more credits for second claim (41 * 25 = 1025)
        for (uint8 i = 0; i < 41; i++) {
            if (i % 10 == 0) {
                vm.warp(block.timestamp + 1 days);
            }
            bytes32 h = keccak256(abi.encodePacked("extra", i));
            bytes32 e = keccak256(abi.encodePacked("xean", i));
            registry.submit(h, e, 200 + uint64(i), EUR,
                LAT, LNG, GEO, USER_A);
            rewards.rewardSubmission(h, 1);
        }

        vm.warp(block.timestamp + 8 days);
        vendClaim.claim(USER_A, 1000);
        assertEq(vendClaim.totalClaimsCount(), 2);
    }

    function test_preview_claim_10000_credits() public view {
        // RATE = 10,000 credits per 1 IFR unit
        // 10,000 * 1e9 / 10,000 = 1e9
        uint256 preview = vendClaim.previewClaim(10_000);
        assertEq(preview, 1e9);
    }

    function test_preview_claim_1000_credits() public view {
        // 1000 * 1e9 / 10000 = 1e8 = 0.1 IFR
        uint256 preview = vendClaim.previewClaim(1_000);
        assertEq(preview, 1e8);
    }

    function test_too_low_amount_reverts() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendClaim.AmountTooLow.selector, 999, 1000)
        );
        vendClaim.claim(USER_A, 999);
    }

    function test_rate_update() public {
        vendClaim.setConversionRate(20_000);
        assertEq(vendClaim.creditsPerIfrUnit(), 20_000);
    }

    function test_rate_zero_reverts() public {
        vm.expectRevert(
            VendClaim.InvalidConversionRate.selector);
        vendClaim.setConversionRate(0);
    }

    function test_can_claim_ready() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        (bool ready,) = vendClaim.canClaim(USER_A);
        assertTrue(ready);
    }

    function test_can_claim_no_wallet() public view {
        (bool ready, string memory reason) =
            vendClaim.canClaim(USER_A);
        assertFalse(ready);
        assertEq(reason, "No wallet registered");
    }

    function test_total_claims_counter() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        assertEq(vendClaim.totalClaimsCount(), 0);
        vendClaim.claim(USER_A, 1000);
        assertEq(vendClaim.totalClaimsCount(), 1);
    }

    function test_pause_blocks_claim() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        vendClaim.pause();
        vm.expectRevert();
        vendClaim.claim(USER_A, 1000);
        vendClaim.unpause();
    }

    function test_nonce_increments() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        assertEq(vendClaim.claimNonce(USER_A), 0);
        vendClaim.claim(USER_A, 1000);
        assertEq(vendClaim.claimNonce(USER_A), 1);
    }

    function test_get_claim_status() public {
        vendClaim.registerWallet(USER_A, WALLET_A);
        (
            uint256 bal,
            uint256 preview,
            ,
            bool walletReg,
        ) = vendClaim.getClaimStatus(USER_A);
        assertGt(bal, 0);
        assertGt(preview, 0);
        assertTrue(walletReg);
    }
}
