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

        // Submit a test price (USER_A is first mover)
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, GEO, USER_A);
    }

    function test_base_reward_first_submission() public {
        rewards.rewardSubmission(HASH1, 1);
        uint256 bal = rewards.getCredits(USER_A);
        // trust=500, dup=1: 100 * 500/1000 / 1 = 50
        assertEq(bal, 50);
    }

    function test_base_reward_duplicate_decay() public {
        rewards.rewardSubmission(HASH1, 3);
        uint256 bal = rewards.getCredits(USER_A);
        // trust=500, dup=3: 100 * 500/1000 / 3 = 16
        assertEq(bal, 16);
    }

    function test_first_mover_bonus_paid_separately() public {
        // Base reward first
        rewards.rewardSubmission(HASH1, 1);
        uint256 afterBase = rewards.getCredits(USER_A);

        // First mover bonus
        rewards.payFirstMoverBonus(HASH1);
        uint256 afterBonus = rewards.getCredits(USER_A);

        // Bonus = 100 * 500/1000 * 2000/1000 = 100
        assertGt(afterBonus, afterBase);
        assertEq(afterBonus - afterBase, 100);
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
        // Submit a duplicate (USER_B, same location)
        registry.submit(HASH2, EAN, 89, EUR,
            LAT, LNG, GEO, USER_B);
        uint256 before = rewards.getCredits(USER_B);
        rewards.payFirstMoverBonus(HASH2);
        // No bonus — not first mover
        assertEq(rewards.getCredits(USER_B), before);
    }

    function test_silent_consensus_reward() public {
        // Auto-verify the submission
        vm.warp(block.timestamp + 73 hours);
        registry.triggerSilentConsensus(HASH1);

        rewards.paySilentConsensusReward(HASH1);
        uint256 bal = rewards.getCredits(USER_A);
        // trust=500, dup=1, silent=0.7x: 100*500/1000*700/1000/1 = 35
        assertEq(bal, 35);
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

    function test_ifr_premium_adds_20_percent() public {
        rewards.setIfrPremium(USER_A, true);
        rewards.rewardSubmission(HASH1, 1);
        uint256 bal = rewards.getCredits(USER_A);
        // base=50, +20%=10, total=60
        assertEq(bal, 60);
    }

    function test_can_claim_threshold() public {
        // Single reward = 50 credits, not enough
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
        rewards.deductCredits(USER_A, 50);
    }

    function test_preview_reward_base() public view {
        uint64 preview = rewards.previewReward(
            USER_A, false, 1, false
        );
        // trust=500: 100 * 500/1000 * 1000/1000 / 1 = 50
        assertEq(preview, 50);
    }

    function test_preview_first_mover_reward() public view {
        uint64 preview = rewards.previewReward(
            USER_A, true, 1, false
        );
        // base=50 + bonus=100 = 150
        assertEq(preview, 150);
    }

    function test_total_credits_earned_tracked() public {
        rewards.rewardSubmission(HASH1, 1);
        assertEq(rewards.totalCreditsEarned(), 50);
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
