# Security Audit — Vendetta Contracts

## Slither Static Analysis (2026-03-17)

### VendRegistry.sol
- 2x divide-before-multiply (INTENTIONAL: grid snapping for location key)
- 2x unused-return (OpenZeppelin ERC1967Utils library)
- **0 High/Medium in project code**

### VendTrust.sol
- 1x incorrect-equality (days_==0 early return, safe)
- 2x unused-return (OpenZeppelin library)
- **0 High/Medium in project code**

### VendRewards.sol
- 1x divide-before-multiply (INTENTIONAL: grid snapping)
- 2x unused-return (OpenZeppelin library)
- **0 High/Medium in project code**

### VendClaim.sol
- 2x unused-return (OpenZeppelin library)
- **0 High/Medium in project code**

### Summary: CLEAN — 0 exploitable findings

## Manual Review Checklist
- [x] CEI Pattern (Checks-Effects-Interactions)
- [x] ReentrancyGuard on all state-mutating functions
- [x] Custom errors (gas efficient)
- [x] Rate limits on-chain (10/day, 3 neg votes/30d)
- [x] Pausable + Owner-only admin functions
- [x] UUPS Proxy correctly implemented
- [x] No selfdestruct
- [x] No delegatecall in user-facing code
- [x] IFR_DECIMALS = 9 (not 18)
- [x] price_cents as uint64 (no float)
- [x] Coordinates as int32 with .round() (no truncation)

## Testnet Deployment (Base Sepolia)

Datum: 2026-03-18
Chain ID: 84532
Deployer: 0x6b36687b0cd4386fb14cf565B67D7862110Fed67

| Contract | Proxy | Basescan |
|---|---|---|
| VendRegistry | 0x77e99917Eca8539c62F509ED1193ac36580A6e7B | [View](https://sepolia.basescan.org/address/0x77e99917Eca8539c62F509ED1193ac36580A6e7B) |
| VendTrust | 0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb | [View](https://sepolia.basescan.org/address/0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb) |
| VendRewards | 0x670D293e3D65f96171c10DdC8d88B96b0570F812 | [View](https://sepolia.basescan.org/address/0x670D293e3D65f96171c10DdC8d88B96b0570F812) |
| VendClaim | 0x4807B77B2E25cD055DA42B09BA4d0aF9e580C60a | [View](https://sepolia.basescan.org/address/0x4807B77B2E25cD055DA42B09BA4d0aF9e580C60a) |

Smoke Tests: 4/4 passed
Basescan Verification: submitted

## Next Steps
- [ ] Mythril deep analysis (Phase 3)
- [ ] Community audit (after mainnet)
- [ ] Bug bounty program (Phase 4)
