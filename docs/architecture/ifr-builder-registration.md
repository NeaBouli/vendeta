# IFR Builder Registration — Vendetta

## Status: BEREIT ZUM EINREICHEN

## GitHub Issue URL
https://github.com/NeaBouli/inferno/issues/new?template=builder-registry.yml

## Formular

**Product Name:** Vendetta

**Category:** integration

**Website / Repository:** https://github.com/NeaBouli/vendeta

**Description:**
Vendetta is a decentralized price transparency network. Users scan real product and service prices in their daily life — anchored on Base L2 blockchain, searchable by GPS radius, with IFR rewards planned (not active).

Integration:
- IFRLock.isLocked() for tier detection (FREE/BRONZE/SILVER/GOLD/PLATINUM)
- IFR partner rewards: planned only. As of 2026-10-03 IFR partner rewards are disabled and no builder is registered; future rewards follow the IFR partner model (valued in EUR, paid in IFR only for verified redemptions, fixed budgets, no refill).
- IFR as sole reward token

Expected user base: Phase 1: 100-1000 (Greece/EU beta), Phase 2: 10,000+ (EU launch)

**Beneficiary Address:** `<VENDETTA_BENEFICIARY_ADDRESS>` (a dedicated Vendetta project wallet will be named when a pilot is approved; it must not be a personal or deployer wallet)

**Integration Type:**
- [x] IFRLock.isLocked() feature gating
- [ ] IFR partner rewards (not available until a pilot is approved)

**Minimum Lock Tiers:**
- BRONZE: 1,000 IFR -> 1.0x reward multiplier
- SILVER: 5,000 IFR -> 1.25x
- GOLD: 10,000 IFR -> 1.5x
- PLATINUM: 50,000 IFR -> 2.0x

**Contracts (Base Sepolia Testnet):**
- VendRegistry: 0x77e99917Eca8539c62F509ED1193ac36580A6e7B
- VendTrust: 0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb
- VendRewards: 0x670D293e3D65f96171c10DdC8d88B96b0570F812
- VendClaim: 0x4807B77B2E25cD055DA42B09BA4d0aF9e580C60a

## Next Steps
1. Open issue on GitHub (link above)
2. Copy form text above
3. Wait for review (~48h)
4. After approval: isBuilder() = true on-chain
