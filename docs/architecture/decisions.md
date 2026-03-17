# Vendeta — Architektur-Entscheidungen (Draft)
> Stand: 2026-03-17 | Status: DRAFT — noch kein Code

## Stack-Entscheidungen

### Blockchain
- **Base L2** (Coinbase) für alle Contracts
  - EVM-kompatibel → IFR Bridge möglich
  - ~$0.001/Tx · Coinbase Smart Wallet (kein MetaMask nötig)
  - Kein Solana (kein EVM, IFR-Bridge zu komplex)
- **ETH Mainnet** nur für IFR Lock Check (isLocked() via Builder API)
- **KEIN eigener Token** — IFR (ifrunit.tech) ist Reward-Token
  - IFR PartnerVault (40M IFR) = Reward-Quelle
  - Vendeta registriert sich als IFR Builder

### Backend / Server
- **Kein eigener Datenbankserver**
- **The Graph Protocol** ersetzt PostgreSQL komplett
  - GraphQL API: <50ms regionale Queries
  - Indiziert Blockchain-Events automatisch
  - Geohash-Prefix-Index = regionaler Beschleuniger
- **Railway** — nur für Phone-OTP-Relay (stateless, speichert nichts)

### Client
- **Flutter** (Android + iOS) mit **Rust FFI** (flutter_rust_bridge)
  - Rust Core (vendeta-core): hash, ean, location, crypto
  - EAN-Validierung, Hash-Generierung, Haversine — alles lokal
- **MapLibre + OpenStreetMap** — kostenlos, open-source
- **Google Places API** — read-only, nur für Store-Namen aus GPS

### Suche & Performance
- **Geohash Precision 5** (z.B. "u284j" = ~1.2km², München-Zentrum)
  - On-chain gespeichert als String
  - The Graph B-Tree Index auf geohash5
  - Regionale Query: 45ms | Cache Hit: 8ms
- **3-Layer Cache**: App (0ms) → The Graph CDN (8ms) → Index (45ms)
- **NIEMALS** direkt von Chain für Search lesen (800ms–3s, nicht skalierbar)

## Warum serverless?
- Keine Serverkosten
- Kein Single Point of Failure
- Blockchain = einzige Wahrheit
- The Graph skaliert automatisch (mehr User → höhere Cache-Rate)
