// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVendTrust {
    function getTrust(bytes32 user_hash)
        external view returns (uint16);

    function getRewardMultiplier(bytes32 user_hash)
        external view
        returns (uint256 numerator, uint256 denominator);

    function getVoteStatus(bytes32 submission_hash)
        external view
        returns (
            uint32 weighted_up,
            uint32 weighted_down,
            uint16 total_voters,
            bool   consensus_reached
        );
}
