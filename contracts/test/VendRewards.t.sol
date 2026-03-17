// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VendRewards.sol";
import "../src/VendRegistry.sol";
import "../src/VendTrust.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VendRewardsTest is Test {
    VendRegistry public registry;
    VendTrust    public trust;
    VendRewards  public rewards;

    bytes32 constant HASH1  = keccak256("sub1");
    bytes32 constant HASH2  = keccak256("sub2");
    bytes32 constant EAN    = keccak256("4006381333931");
    bytes32 constant USER_A = keccak256("user_a");
    bytes32 constant USER_B = keccak256("user_b");
    bytes3  constant EUR    = "EUR";
    int32   constant LAT    = 48_137_154;
    int32   constant LNG    = 11_576_124;
    string  constant GEO    = "u281z";

    function setUp() public {
        VendRegistry ri = new VendRegistry();
        ERC1967Proxy rp = new ERC1967Proxy(
            address(ri),
            abi.encodeCall(VendRegistry.initialize, (address(this)))
        );
        registry = VendRegistry(address(rp));

        VendTrust ti = new VendTrust();
        ERC1967Proxy tp = new ERC1967Proxy(
            address(ti),
            abi.encodeCall(VendTrust.initialize,
                (address(this), address(registry)))
        );
        trust = VendTrust(address(tp));

        VendRewards rwi = new VendRewards();
        ERC1967Proxy rwp = new ERC1967Proxy(
            address(rwi),
            abi.encodeCall(VendRewards.initialize,
                (address(this), address(registry), address(trust)))
        );
        rewards = VendRewards(address(rwp));

        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, GEO, USER_A);
    }

    // ── BASE REWARD (FREE tier = 0.5x) ──────

    function test_base_reward_free_tier() public {
        rewards.rewardSubmission(HASH1, 1);
        uint256 bal = rewards.getCredits(USER_A);
        // trust=500, tier=FREE(0.5x), dup=1:
        // 100 * 500/1000 * 500/1000 / 1 = 25
        assertEq(bal, 25);
    }

    function test_base_reward_duplicate_decay() public {
        rewards.rewardSubmission(HASH1, 3);
        uint256 bal = rewards.getCredits(USER_A);
        // 100 * 500/1000 * 500/1000 / 3 = 8
        assertEq(bal, 8);
    }

    // ── TIER SYSTEM ─────────────────────────

    function test_bronze_tier_reward() public {
        rewards.setTier(USER_A, 1); // BRONZE = 1.0x
        rewards.rewardSubmission(HASH1, 1);
        uint256 bal = rewards.getCredits(USER_A);
        // 100 * 500/1000 * 1000/1000 / 1 = 50
        assertEq(bal, 50);
    }

    function test_gold_tier_reward() public {
        rewards.setTier(USER_A, 3); // GOLD = 1.5x
        rewards.rewardSubmission(HASH1, 1);
        uint256 bal = rewards.getCredits(USER_A);
        // 100 * 500/1000 * 1500/1000 / 1 = 75
        assertEq(bal, 75);
    }

    function test_platinum_tier_reward() public {
        rewards.setTier(USER_A, 4); // PLATINUM = 2.0x
        rewards.rewardSubmission(HASH1, 1);
        uint256 bal = rewards.getCredits(USER_A);
        // 100 * 500/1000 * 2000/1000 / 1 = 100
        assertEq(bal, 100);
    }

    function test_set_tier_invalid_reverts() public {
        vm.expectRevert("Invalid tier");
        rewards.setTier(USER_A, 5);
    }

    // ── FIRST MOVER ─────────────────────────

    function test_first_mover_bonus_paid_separately() public {
        rewards.rewardSubmission(HASH1, 1);
        uint256 afterBase = rewards.getCredits(USER_A);

        rewards.payFirstMoverBonus(HASH1);
        uint256 afterBonus = rewards.getCredits(USER_A);

        // FREE tier: bonus = 100*500/1000*2000/1000*500/1000 = 50
        assertGt(afterBonus, afterBase);
        assertEq(afterBonus - afterBase, 50);
    }

    function test_first_mover_bonus_only_once() public {
        rewards.payFirstMoverBonus(HASH1);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendRewards.AlreadyPaid.selector,
                HASH1, "first_mover")
        );
        rewards.payFirstMoverBonus(HASH1);
    }

    function test_non_first_mover_gets_no_bonus() public {
        registry.submit(HASH2, EAN, 89, EUR,
            LAT, LNG, GEO, USER_B);
        uint256 before = rewards.getCredits(USER_B);
        rewards.payFirstMoverBonus(HASH2);
        assertEq(rewards.getCredits(USER_B), before);
    }

    // ── SILENT CONSENSUS ────────────────────

    function test_silent_consensus_reward() public {
        vm.warp(block.timestamp + 73 hours);
        registry.triggerSilentConsensus(HASH1);

        rewards.paySilentConsensusReward(HASH1);
        uint256 bal = rewards.getCredits(USER_A);
        // FREE: 100*500/1000*700/1000*500/1000/1 = 17
        assertEq(bal, 17);
    }

    function test_silent_consensus_only_once() public {
        vm.warp(block.timestamp + 73 hours);
        registry.triggerSilentConsensus(HASH1);
        rewards.paySilentConsensusReward(HASH1);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendRewards.AlreadyPaid.selector,
                HASH1, "silent_consensus")
        );
        rewards.paySilentConsensusReward(HASH1);
    }

    // ── PREVIEW ─────────────────────────────

    function test_preview_reward_free_tier() public view {
        uint64 preview = rewards.previewReward(
            USER_A, false, 1, false
        );
        // FREE: 100*500/1000*1000/1000*500/1000 = 25
        assertEq(preview, 25);
    }

    function test_preview_first_mover_free_tier() public view {
        uint64 preview = rewards.previewReward(
            USER_A, true, 1, false
        );
        // base=25 + bonus=50 = 75
        assertEq(preview, 75);
    }

    // ── MISC ────────────────────────────────

    function test_can_claim_threshold() public {
        rewards.rewardSubmission(HASH1, 1);
        assertFalse(rewards.canClaim(USER_A));
    }

    function test_deduct_credits_requires_min_claim() public {
        rewards.rewardSubmission(HASH1, 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendRewards.InsufficientCredits.selector,
                USER_A, rewards.getCredits(USER_A), 1000)
        );
        rewards.deductCredits(USER_A, 25);
    }

    function test_total_credits_earned_tracked() public {
        rewards.rewardSubmission(HASH1, 1);
        assertEq(rewards.totalCreditsEarned(), 25);
    }

    function test_pause_blocks_rewards() public {
        rewards.pause();
        vm.expectRevert();
        rewards.rewardSubmission(HASH1, 1);
        rewards.unpause();
        rewards.rewardSubmission(HASH1, 1);
        assertGt(rewards.getCredits(USER_A), 0);
    }
}
