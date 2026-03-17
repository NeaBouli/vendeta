// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVendRewards {
    function getCredits(bytes32 user_hash)
        external view returns (uint256);

    function canClaim(bytes32 user_hash)
        external view returns (bool);

    function deductCredits(
        bytes32 user_hash,
        uint256 amount
    ) external;

    function MIN_CLAIM()
        external view returns (uint64);
}
