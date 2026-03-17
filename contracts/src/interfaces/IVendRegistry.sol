// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVendRegistry {
    struct Submission {
        bytes32 ean_hash;
        uint64  price_cents;
        bytes3  currency;
        int32   lat6;
        int32   lng6;
        string  geohash5;
        bytes32 user_hash;
        uint32  timestamp;
        bool    is_first_mover;
        uint8   status;
        uint32  votes_up;
        uint32  votes_down;
        uint32  auto_verify_at;
    }

    function getSubmission(bytes32 hash)
        external view returns (Submission memory);

    function hashExists(bytes32 hash)
        external view returns (bool);
}
