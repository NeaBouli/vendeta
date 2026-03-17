# IFR Builder Registration — Vendetta

## Status: TODO (Core Dev Action Required)

## Steps
1. Open GitHub Issue:
   https://github.com/NeaBouli/inferno/issues/new
   Template: builder-registry.yml

2. Fill fields:
   - Product Name: Vendetta
   - Category: integration
   - Description: Decentralized price transparency network.
     Users earn IFR by scanning real prices.
   - Website: github.com/NeaBouli/vendeta
   - Beneficiary: [Deployer wallet address]
   - Integration Type: IFRLock.isLocked() + PartnerVault rewards

3. After approval (~48h review):
   - isBuilder(wallet) = true on-chain
   - Telegram Dev&Builder access
   - PartnerVault beneficiary registered

## IFR Lock Integration (Phase 3)
```
isLocked(wallet, 1_000_000_000_000)  // 1000 IFR → Bronze
isLocked(wallet, 5_000_000_000_000)  // 5000 IFR → Silver
isLocked(wallet, 10_000_000_000_000) // 10000 IFR → Gold
isLocked(wallet, 50_000_000_000_000) // 50000 IFR → Platinum
```

## VendRewards.sol Phase 3 Update
`setTier()` will be replaced by automatic `isLocked()` check.
No owner call needed. Resolver: Alchemy API -> isLocked() -> Base L2 setTier().
