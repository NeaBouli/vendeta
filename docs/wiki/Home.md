# Vendetta Wiki

> Decentralized Price Transparency Network
> Built on Base L2 · Powered by $IFR

## Status

| Component | Status |
|---|---|
| Smart Contracts | ✅ Live — Base Sepolia |
| Subgraph | ✅ Live — The Graph Studio |
| Flutter App | ✅ Feature Complete |
| IFR Builder | ✅ Registered (Issue #12) |
| Mainnet | ⏳ After Beta |

## Quick Links

| | |
|---|---|
| [Getting Started](Getting-Started) | Setup dev environment |
| [Architecture](Architecture) | System design |
| [Smart Contracts](Smart-Contracts) | Contract docs + ABIs |
| [Rust Core](Rust-Core) | Core library reference |
| [The Graph](The-Graph) | Subgraph + queries |
| [Wallet](Wallet) | HD wallet architecture |
| [FAQ](FAQ) | Common questions |
| [Contributing](Contributing) | How to contribute |

## What is Vendetta?

Vendetta is an open-source, community-driven platform where consumers record prices for everyday products and services — anchored on blockchain, searchable by GPS radius, rewarded with IFR tokens.

## Live Deployments

### Base Sepolia (Testnet)
| Contract | Address |
|---|---|
| VendRegistry | `0x77e99917Eca8539c62F509ED1193ac36580A6e7B` |
| VendTrust | `0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb` |
| VendRewards | `0x670D293e3D65f96171c10DdC8d88B96b0570F812` |
| VendClaim | `0x4807B77B2E25cD055DA42B09BA4d0aF9e580C60a` |

### The Graph
Endpoint: `https://api.studio.thegraph.com/query/1744627/vendetta-price-network/v0.1.0`

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Android + iOS) |
| Core Library | Rust + flutter_rust_bridge |
| Blockchain | Base L2 (Coinbase) |
| Token | IFR (ifrunit.tech) |
| Search | The Graph Protocol |
| Maps | flutter_map + OpenStreetMap |
| Identity | Nullifier Pattern (GDPR) |
| Wallet | BIP39/BIP44 HD Wallet |

## Repository Structure

```
vendeta/
├── core/          Rust core library (36 tests)
├── contracts/     Solidity smart contracts (60 tests)
├── mobile/        Flutter app
├── subgraph/      The Graph subgraph
└── docs/          Architecture + wiki
```
