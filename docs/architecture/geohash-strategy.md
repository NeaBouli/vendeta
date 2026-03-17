# Vendeta — Geohash & The Graph Strategie (Draft)

## Was ist Geohash?
GPS-Koordinaten → kurzer String. Gleicher Prefix = gleiche Region.
```
48.137154, 11.576124  →  "u284j"
Precision 5 = ~1.2km² (Stadtviertel) ← Vendeta Standard
```

## Query-Performance
| Methode | Latenz | Skalierung |
|---|---|---|
| Geohash Cache Hit (The Graph CDN) | 8ms | ∞ |
| Geohash Index Query (The Graph) | 45ms | sehr gut |
| Bounding-Box Query | 180ms | gut |
| Direkt von Base L2 (eth_call) | 800ms–3s | ❌ nicht für Search |
| Haversine auf alle Submissions (naiv) | 2400ms+ | ❌ |

## The Graph Subgraph Schema (Draft)
```graphql
type Submission @entity {
  id:           Bytes!
  ean_hash:     Bytes!
  price_cents:  BigInt!
  lat6:         Int!
  lng6:         Int!
  geohash5:     String!   # ← INDEX
  user_hash:    Bytes!
  is_first:     Boolean!
  timestamp:    BigInt!
  trust_score:  Int!
}
```

## 3-Layer Cache
1. App Cache (Flutter, on-device): 0ms, TTL 5min
2. The Graph CDN: 8ms, häufige Queries
3. The Graph Index (PostgreSQL intern): 45ms

## Überlastungs-Schutz
- 100 User: alles normal
- 1.000 User: The Graph skaliert automatisch, Gas minimal
- 10.000 User (viral): Cache-Rate steigt auf 96% → paradox schneller
- Spam-Attack: on-chain Rate Limit schützt, Angreifer zahlt Gas ohne Wirkung
- Kein zentraler Server = kein klassischer DDoS-Angriffspunkt
