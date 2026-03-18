# Smart Contracts

## Overview

Vendetta uses 4 upgradeable (UUPS) smart contracts on Base L2:

| Contract | Purpose | Tests |
|---|---|---|
| VendRegistry.sol | Submissions, duplicates, first-mover | 12 ✅ |
| VendTrust.sol | Trust 0-1000, weighted votes, locality lock | 14 ✅ |
| VendRewards.sol | Credits, tier multipliers, IFR premium | 17 ✅ |
| VendClaim.sol | Credits → IFR bridge, 7d cooldown | 17 ✅ |

**Total: 60 Forge tests passing**

## Live Addresses (Base Sepolia)

| Contract | Proxy | Basescan |
|---|---|---|
| VendRegistry | `0x77e99917...` | [View](https://sepolia.basescan.org/address/0x77e99917Eca8539c62F509ED1193ac36580A6e7B) |
| VendTrust | `0x769928aB...` | [View](https://sepolia.basescan.org/address/0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb) |
| VendRewards | `0x670D293e...` | [View](https://sepolia.basescan.org/address/0x670D293e3D65f96171c10DdC8d88B96b0570F812) |
| VendClaim | `0x4807B77B...` | [View](https://sepolia.basescan.org/address/0x4807B77B2E25cD055DA42B09BA4d0aF9e580C60a) |

Deployed: 2026-03-18
Deployer: `0x6b36687b0cd4386fb14cf565B67D7862110Fed67`
Security: Slither — 0 High/Medium findings

## Contract Interactions

```
VendRegistry → VendTrust → VendRewards → VendClaim
     │              │             │            │
  submit()     voteTrust()   creditReward()  claim()
  firstMover   consensus     tierMultiplier  cooldown
  dupCheck     localityLock  ifrPremium      bridge
```

## IFR Tier System

| Tier | Lock | Multiplier |
|---|---|---|
| FREE | 0 IFR | 0.5× |
| Bronze | 1,000 IFR | 1.0× |
| Silver | 5,000 IFR | 1.25× |
| Gold | 10,000 IFR | 1.5× |
| Platinum | 50,000 IFR | 2.0× |

## Development

```bash
cd contracts
forge install
forge build
forge test -vv
```
