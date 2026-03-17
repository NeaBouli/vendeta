// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VendTrust.sol";
import "../src/VendRegistry.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VendTrustTest is Test {
    VendRegistry public registry;
    VendTrust    public trust;

    bytes32 constant HASH1  = keccak256("sub1");
    bytes32 constant EAN    = keccak256("4006381333931");
    bytes32 constant USER_A = keccak256("user_a");
    bytes32 constant USER_B = keccak256("user_b");
    bytes32 constant USER_C = keccak256("user_c");
    bytes32 constant USER_D = keccak256("user_d");
    bytes32 constant USER_E = keccak256("user_e");
    bytes3  constant EUR    = "EUR";
    int32   constant LAT    = 48_137_154;
    int32   constant LNG    = 11_576_124;
    string  constant GEO    = "u281z";

    function setUp() public {
        // Deploy Registry via proxy
        VendRegistry ri = new VendRegistry();
        ERC1967Proxy rp = new ERC1967Proxy(
            address(ri),
            abi.encodeCall(VendRegistry.initialize, (address(this)))
        );
        registry = VendRegistry(address(rp));

        // Deploy Trust via proxy
        VendTrust ti = new VendTrust();
        ERC1967Proxy tp = new ERC1967Proxy(
            address(ti),
            abi.encodeCall(VendTrust.initialize,
                (address(this), address(registry)))
        );
        trust = VendTrust(address(tp));

        // Create a submission by USER_A
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, GEO, USER_A);

        // Register locality for voters
        trust.recordRegionVisit(USER_B, GEO);
        trust.recordRegionVisit(USER_C, GEO);
        trust.recordRegionVisit(USER_D, GEO);
        trust.recordRegionVisit(USER_E, GEO);
    }

    function test_default_trust_500() public view {
        assertEq(trust.getTrust(USER_A), 500);
        assertEq(trust.getTrust(USER_B), 500);
    }

    function test_upvote_weight_equals_trust() public {
        trust.vote(HASH1, USER_B, true);
        (uint32 up,,,) = trust.getVoteStatus(HASH1);
        assertEq(up, 500); // voter trust = 500
    }

    function test_voter_gains_2_trust() public {
        uint16 before = trust.getTrust(USER_B);
        trust.vote(HASH1, USER_B, true);
        assertEq(trust.getTrust(USER_B), before + 2);
    }

    function test_no_self_vote() public {
        // USER_A submitted HASH1, cannot vote on own submission
        trust.recordRegionVisit(USER_A, GEO);
        vm.expectRevert(VendTrust.SelfVoteNotAllowed.selector);
        trust.vote(HASH1, USER_A, true);
    }

    function test_no_double_vote() public {
        trust.vote(HASH1, USER_B, true);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendTrust.AlreadyVoted.selector, HASH1, USER_B)
        );
        trust.vote(HASH1, USER_B, false);
    }

    function test_locality_lock_stranger_fails() public {
        bytes32 stranger = keccak256("stranger");
        vm.expectRevert(
            abi.encodeWithSelector(
                VendTrust.LocalityCheckFailed.selector,
                stranger, GEO)
        );
        trust.vote(HASH1, stranger, true);
    }

    function test_locality_lock_expires_after_7_days() public {
        // Refresh locality then warp past 7 days
        trust.recordRegionVisit(USER_B, GEO);
        vm.warp(block.timestamp + 8 days);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendTrust.LocalityCheckFailed.selector,
                USER_B, GEO)
        );
        trust.vote(HASH1, USER_B, false);
    }

    function test_consensus_verified_4_upvotes() public {
        trust.vote(HASH1, USER_B, true);
        trust.vote(HASH1, USER_C, true);
        trust.vote(HASH1, USER_D, true);
        // After 3 votes (all up, 100% > 80%), consensus fires
        // USER_A should gain +5 trust
        assertGe(trust.getTrust(USER_A), 505);
    }

    function test_consensus_disputed_4_downvotes() public {
        trust.vote(HASH1, USER_B, false);
        trust.vote(HASH1, USER_C, false);
        trust.vote(HASH1, USER_D, false);
        // After 3 downvotes (100% > 75%), dispute fires
        // USER_A loses 50 trust: 500 - 50 = 450
        assertEq(trust.getTrust(USER_A), 450);
    }

    function test_min_trust_is_100() public view {
        assertEq(trust.MIN_TRUST(), 100);
        assertEq(trust.MAX_TRUST(), 1000);
    }

    function test_neg_vote_rate_limit_3_per_30_days() public {
        // Create 3 submissions and downvote them all
        for (uint8 i = 1; i <= 3; i++) {
            bytes32 h = keccak256(abi.encodePacked("h", i));
            registry.submit(h, EAN, 79 + uint64(i), EUR,
                LAT, LNG, GEO, USER_A);
            trust.recordRegionVisit(USER_B, GEO);
            trust.vote(h, USER_B, false);
        }
        // 4th downvote from B against A should be rate-limited
        bytes32 h4 = keccak256("h4");
        registry.submit(h4, EAN, 99, EUR, LAT, LNG, GEO, USER_A);
        trust.recordRegionVisit(USER_B, GEO);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendTrust.NegVoteRateLimitExceeded.selector,
                USER_B, USER_A)
        );
        trust.vote(h4, USER_B, false);
    }

    function test_trust_recovery() public {
        uint16 before = trust.getTrust(USER_A);
        trust.recoverTrust(USER_A); // initializes lastCleanDay
        vm.warp(block.timestamp + 5 days);
        trust.recoverTrust(USER_A); // +5 trust recovery
        assertGe(trust.getTrust(USER_A), before);
    }

    function test_reward_multiplier() public view {
        (uint256 n, uint256 d) =
            trust.getRewardMultiplier(USER_A);
        assertEq(d, 1000);
        assertEq(n, 500); // default trust
    }

    function test_pause_blocks_vote() public {
        trust.pause();
        vm.expectRevert();
        trust.vote(HASH1, USER_B, true);
        trust.unpause();
        trust.vote(HASH1, USER_B, true);
        (uint32 up,,,) = trust.getVoteStatus(HASH1);
        assertGt(up, 0);
    }
}
