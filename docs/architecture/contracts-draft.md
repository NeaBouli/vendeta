# Vendetta — Smart Contracts Draft (Base L2)
> Status: DRAFT — noch nicht implementiert

## 4 Contracts, je eine Verantwortlichkeit

### VendRegistry.sol
Einzige Wahrheit für alle Submissions.
```solidity
// DRAFT — nicht finaler Code
mapping(bytes32 => bool) public hashExists;
mapping(bytes32 => Submission) public submissions;

struct Submission {
    bytes32  ean_hash;
    uint64   price_cents;
    int32    lat6;          // latitude × 1e6
    int32    lng6;          // longitude × 1e6
    string   geohash5;      // für The Graph Index
    bytes32  user_hash;     // HMAC phone hash
    uint32   timestamp;
    bool     is_first_mover;
}

function submit(
    bytes32 hash,
    bytes32 ean_hash,
    uint64  price_cents,
    int32   lat6,
    int32   lng6,
    string  calldata geohash5,
    bytes32 user_hash
) external {
    require(!hashExists[hash], "Duplicate");
    // Rate limit: max 10/user/hour
    // First mover check: locationHasEan(lat6, lng6, ean_hash, 10m)
    // Emit: SubmissionCreated(...)
}
```

### VendTrust.sol
Community-Voting → Trust Score (0–1000).
```solidity
// DRAFT
mapping(bytes32 => uint16) public trustScore;
// Default: 500 (new user)
// 4:1 Consensus gegen User → -50 trust
// Korrekter Vote → +2 trust
// trustScore kann 0 erreichen → Reward = 0
```

### VendRewards.sol
Reward-Berechnung und Credit-Ledger.
```solidity
// DRAFT
// reward = base_reward(100)
//        × (trust/1000)           // trust multiplier
//        × (first ? 2.0 : 1/n)   // first mover bonus / dup decay
// Minimum claim: 1000 credits (spam prevention)
// IFR Premium (isLocked = true) → +20% bonus
```

### VendClaim.sol
Credits → IFR Token (Bridge Base L2 → ETH Mainnet).
```solidity
// DRAFT
// User claimt Credits → IFR Conversion
// Rate: dynamisch (PartnerVault balance / total credits outstanding)
// Bridge: Base L2 → ETH Mainnet → IFR PartnerVault → User wallet
```

## Koordinaten on-chain: Kein Float!
```
lat: 48.137154 → int32: 48137154  (× 1e6)
lng: 11.576124 → int32: 11576124  (× 1e6)
Precision: 6 Dezimalstellen = ~11cm Genauigkeit
Rust FFI konvertiert: (lat * 1_000_000) as i32
```
