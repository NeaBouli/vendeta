# The Graph — Subgraph Documentation

## Overview

The Vendetta subgraph indexes all 4 smart contracts on Base L2
and exposes a GraphQL API for the Flutter app.

**No backend server needed.** The Graph replaces PostgreSQL entirely.

## Key Entities

| Entity | Description |
|---|---|
| Submission | Price entry with GPS, EAN, hash |
| User | Trust score, tier, credits balance |
| Vote | Community vote with weighted trust |
| ConsensusEvent | Verified or disputed outcome |
| RewardEvent | Credits earned per action |
| ClaimEvent | IFR claim with wallet + amount |
| GeohashRegion | Regional stats (submission count, avg price) |
| GlobalStats | Protocol-wide totals |

## Key Queries

### Nearby Prices (main search)
```graphql
query NearbyPrices($geo: String!, $currency: String!) {
  submissions(
    where: {
      geohash5_starts_with: $geo,
      currency: $currency,
      status_in: [1, 2]
    }
    orderBy: timestamp
    orderDirection: desc
    first: 100
  ) {
    id
    price_cents
    currency
    lat6
    lng6
    is_first_mover
    timestamp
  }
}
```

### User Credits & Status
```graphql
query UserStatus($user: Bytes!) {
  user(id: $user) {
    trust_score
    tier_level
    current_credits
    total_claimed
    total_submissions
    last_claim_at
  }
}
```

### Regional Stats
```graphql
query RegionStats($geo: String!) {
  geohashRegion(id: $geo) {
    submission_count
    avg_price_cents
    last_submission
  }
}
```

### Global Protocol Stats
```graphql
query Stats {
  globalStats(id: "global") {
    total_submissions
    total_users
    total_credits_earned
    total_ifr_claimed
  }
}
```

## Deployment
```bash
cd subgraph
npm install
npx graph codegen
npx graph build
npx graph deploy vendetta/base-l2
```

Contract addresses in `subgraph.yaml` must be updated
before deployment with real Base L2 mainnet addresses.
