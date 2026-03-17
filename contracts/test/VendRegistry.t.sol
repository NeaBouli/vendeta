// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/VendRegistry.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VendRegistryTest is Test {
    VendRegistry public registry;

    bytes32 constant HASH1 = keccak256("test_hash_1");
    bytes32 constant EAN   = keccak256("4006381333931");
    bytes32 constant USER1 = keccak256("user_hash_1");
    bytes32 constant USER2 = keccak256("user_hash_2");
    bytes3  constant EUR   = "EUR";
    int32   constant LAT   = 48_137_154;  // Munich lat × 1e6
    int32   constant LNG   = 11_576_124;  // Munich lng × 1e6

    function setUp() public {
        VendRegistry impl = new VendRegistry();
        bytes memory data = abi.encodeCall(
            VendRegistry.initialize, (address(this))
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl), data
        );
        registry = VendRegistry(address(proxy));
    }

    function test_submit_success() public {
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        VendRegistry.Submission memory s =
            registry.getSubmission(HASH1);
        assertEq(s.price_cents, 79);
        assertEq(s.currency, EUR);
        assertTrue(s.is_first_mover);
        assertEq(s.status, 0); // pending
        assertTrue(registry.hashExists(HASH1));
    }

    function test_duplicate_hash_reverts() public {
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                VendRegistry.HashAlreadyExists.selector,
                HASH1
            )
        );
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER2);
    }

    function test_first_mover_flag() public {
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        VendRegistry.Submission memory s1 =
            registry.getSubmission(HASH1);
        assertTrue(s1.is_first_mover);

        bytes32 hash2 = keccak256("test_hash_2");
        registry.submit(hash2, EAN, 89, EUR,
            LAT, LNG, "u281z", USER2);
        VendRegistry.Submission memory s2 =
            registry.getSubmission(hash2);
        assertFalse(s2.is_first_mover);
    }

    function test_rate_limit_10_per_day() public {
        for (uint8 i = 0; i < 10; i++) {
            bytes32 h = keccak256(abi.encodePacked("hash", i));
            registry.submit(h, EAN, 79 + i, EUR,
                LAT, LNG, "u281z", USER1);
        }
        bytes32 h11 = keccak256("hash_11");
        vm.expectRevert();
        registry.submit(h11, EAN, 99, EUR,
            LAT, LNG, "u281z", USER1);
    }

    function test_silent_consensus_after_72h() public {
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        vm.warp(block.timestamp + 73 hours);
        registry.triggerSilentConsensus(HASH1);
        VendRegistry.Submission memory s =
            registry.getSubmission(HASH1);
        assertEq(s.status, 1); // auto_verified
    }

    function test_silent_consensus_fails_before_72h() public {
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        vm.warp(block.timestamp + 71 hours);
        vm.expectRevert("72h not elapsed");
        registry.triggerSilentConsensus(HASH1);
    }

    function test_invalid_price_reverts() public {
        vm.expectRevert(VendRegistry.InvalidPrice.selector);
        registry.submit(HASH1, EAN, 0, EUR,
            LAT, LNG, "u281z", USER1);
    }

    function test_invalid_currency_reverts() public {
        vm.expectRevert();
        registry.submit(HASH1, EAN, 79, "USD",
            LAT, LNG, "u281z", USER1);
    }

    function test_invalid_coordinates_reverts() public {
        vm.expectRevert();
        registry.submit(HASH1, EAN, 79, EUR,
            91_000_000, LNG, "u281z", USER1);
    }

    function test_pause_blocks_submit() public {
        registry.pause();
        vm.expectRevert();
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        registry.unpause();
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        assertTrue(registry.hashExists(HASH1));
    }

    function test_coordinate_boundary_valid() public {
        // North Pole edge case
        bytes32 h = keccak256("northpole");
        registry.submit(h, EAN, 79, EUR,
            90_000_000, 0, "u281z", USER1);
        assertTrue(registry.hashExists(h));
    }

    function test_total_submissions_counter() public {
        assertEq(registry.totalSubmissions(), 0);
        registry.submit(HASH1, EAN, 79, EUR,
            LAT, LNG, "u281z", USER1);
        assertEq(registry.totalSubmissions(), 1);
    }
}
