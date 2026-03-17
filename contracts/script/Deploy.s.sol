// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/VendRegistry.sol";
import "../src/VendTrust.sol";
import "../src/VendRewards.sol";
import "../src/VendClaim.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployVendetta is Script {
    uint256 constant INITIAL_RATE = 10_000;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerKey);

        // 1. VendRegistry
        VendRegistry regImpl = new VendRegistry();
        ERC1967Proxy regProxy = new ERC1967Proxy(
            address(regImpl),
            abi.encodeCall(VendRegistry.initialize, (deployer))
        );
        address registry = address(regProxy);
        console.log("VendRegistry:", registry);

        // 2. VendTrust
        VendTrust trustImpl = new VendTrust();
        ERC1967Proxy trustProxy = new ERC1967Proxy(
            address(trustImpl),
            abi.encodeCall(VendTrust.initialize, (deployer, registry))
        );
        address trust = address(trustProxy);
        console.log("VendTrust:", trust);

        // 3. VendRewards
        VendRewards rewardsImpl = new VendRewards();
        ERC1967Proxy rewardsProxy = new ERC1967Proxy(
            address(rewardsImpl),
            abi.encodeCall(VendRewards.initialize, (deployer, registry, trust))
        );
        address rewards = address(rewardsProxy);
        console.log("VendRewards:", rewards);

        // 4. VendClaim
        VendClaim claimImpl = new VendClaim();
        ERC1967Proxy claimProxy = new ERC1967Proxy(
            address(claimImpl),
            abi.encodeCall(VendClaim.initialize, (deployer, rewards, INITIAL_RATE))
        );
        address claim = address(claimProxy);
        console.log("VendClaim:", claim);

        // 5. Post-deploy: authorize VendClaim
        VendRewards(rewards).setAuthorizedClaimer(claim);
        console.log("VendClaim authorized as claimer");

        vm.stopBroadcast();

        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("VendRegistry:", registry);
        console.log("VendTrust:   ", trust);
        console.log("VendRewards: ", rewards);
        console.log("VendClaim:   ", claim);
    }
}
