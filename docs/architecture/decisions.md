# Vendetta — Finale Architektur-Entscheidungen
> Stand: 2026-03-17 | Status: FINAL — Implementierung bereit
> Entwicklungs-Standort: Griechenland (EU)
> Rollout: Europa Phase 1 → Global Phase 2+

## Rollout-Strategie
- Phase 1: Europa (EU + GBP + CHF Raum)
  - DSGVO gilt ✅
  - MiCA (EU Crypto-Rahmen) gilt ✅
  - IFR als Utility Token unter MiCA vertretbar ✅
  - Griechische Unternehmensstruktur vorhanden ✅
- Phase 2: UK, Schweiz, Norwegen
- Phase 3: Global (nach länderspezifischen Rechtsgutachten)
- Explizit ausgeschlossen Phase 1: USA, China, Russland

## Stack (FINAL)

### Blockchain
- Base L2 (Coinbase) für ALLE Contracts
  - EVM-kompatibel → IFR-Bridge möglich
  - ~$0.001/Tx
  - Coinbase Smart Wallet (kein MetaMask nötig)
- ETH Mainnet: nur IFR Lock Check (isLocked() Builder API)
- KEIN eigener Token — IFR (ifrunit.tech) = Reward-Token
- IFR PartnerVault (40M IFR) = Reward-Quelle
- Vendetta registriert als offizieller IFR Builder

### Contract-Architektur (FINAL)
- Alle 4 Contracts: Transparent Proxy Pattern (EIP-1967)
- Upgrade: nur via Timelock (48h) + 3-of-5 Multisig
- Alle Contracts: Pausable + ReentrancyGuard
- Checks-Effects-Interactions Pattern überall
- Slither + Mythril vor jedem Deployment

### 4 Contracts (Base L2)
1. VendRegistry.sol — Submissions, Duplikat-Schutz,
                       First-Mover, Geohash, Währung
2. VendTrust.sol    — Trust Scores, Community Voting,
                       Locality Lock, gewichtete Votes
3. VendRewards.sol  — Credit-Berechnung, Ledger,
                       Silent Consensus, IFR Premium
4. VendClaim.sol    — Credits → IFR Bridge Base L2
                       → ETH Mainnet → PartnerVault

### Backend / Server
- KEIN eigener Datenbankserver
- The Graph Protocol (dezentrales Netzwerk, NICHT
  Hosted Service) für alle Queries
- Railway: NUR Phone/OTP-Relay (stateless, kein State)
- Kein PostgreSQL, kein Redis, kein Axum-Server

### Client
- Flutter (Android + iOS) + flutter_rust_bridge
- vendeta-core (Rust): hash, ean, location, crypto,
  nullifier, geohash, currency
- MapLibre + OpenStreetMap (primär, weltweit)
- Google Places API (read-only, Store-Namen, nur EU)
- OSM Nominatim als Fallback

### Suche & Performance
- Geohash Precision 5 (~1.2km², adaptiv Phase 3)
- Multi-Cell Query: 9 Nachbar-Zellen immer abfragen
- 3-Layer Cache: App(0ms) → CDN(8ms) → Index(45ms)
- NIEMALS direkt von Chain für Search

## Datenmodell (FINAL, on-chain)

### Koordinaten
- int32 × 1.000.000 (6 Dezimalstellen = ~11cm)
- IMMER .round() vor Cast (kein truncation!)
- Rust: (lat * 1_000_000.0_f64).round() as i32

### Währung
- ISO 4217, bytes3 on-chain ("EUR", "GBP", "CHF")
- price_cents = kleinste Währungseinheit
- EUR: 2 Dezimalstellen → 0.79€ = 79
- Nur gleiche Währungen werden verglichen
- Phase 1: primär EUR

### Geohash
- String, Precision 5, on-chain gespeichert
- Ermöglicht The Graph B-Tree Index
- Client berechnet via Rust FFI

## Identity (FINAL)

### Nullifier-Pattern (ZK-inspiriert)
- KEIN HMAC(phone, device_id) — unsicher
  (phone-Raum zu klein, brute-forceable in 0.2s)
- Stattdessen: zufälliger 256-bit Nullifier
- Prozess:
  1. User gibt Phone ein (nur für OTP)
  2. Railway: OTP-Verifikation → nullifier = random_256bit()
  3. Railway löscht phone→nullifier SOFORT
  4. App: device_salt = SecureEnclave::random()
  5. user_hash = SHA256(nullifier || device_salt)
  6. seed_phrase = BIP39(nullifier) → 12 Wörter
  7. Phone wird vergessen, user_hash on-chain
- Recovery bei Handywechsel: 12-Wort Seed Phrase
- DSGVO-konform: kein Personenbezug mehr möglich

## Trust-System (FINAL)

### Werte
- Score: 0–1000, default: 500 (new user)
- Reward-Multiplier: trust/1000
- Minimum effektiver Trust: 100 (nie 0)

### Voting-Regeln
- Trust-gewichtete Votes: vote_weight = voter_trust/1000
- Locality Lock: Voter muss in submission_geohash5
  Region in letzten 7 Tagen gewesen sein
- Rate-Limit: max 3 neg. Votes von A gegen B / 30 Tage
- Voter-Accountability: systematische Falsch-Voter
  verlieren selbst Trust
- Self-Vote verboten: user_hash ≠ submission.user_hash

### Consensus
- Minimum 3 Votes für Wirkung
- 4:1 gewichtete Mehrheit → Verlierer -50 Trust
- Silent Consensus: 72h ohne Downvote = auto_verified
  → Löst Cold-Start-Problem
- Recovery: +1 Trust/Tag bei 0 negativen Votes

## Reward-System (FINAL)
- base_reward = 100 credits
- first_mover_bonus = 2.0× (nur nach 1. Bestätigung!)
- duplicate_decay = base / dup_count
- trust_multiplier = trust / 1000
- silent_consensus_multiplier = 0.7× (weniger als echter Vote)
- IFR_premium_bonus = +20% (isLocked = true via IFR API)
- Minimum Claim: 1000 credits
- Conversion Rate: dynamisch, UI zeigt Rate vor Claim

## Anti-Gaming (FINAL)
1. Rate Limit on-chain: 10 Submissions/user/location/Tag
2. GPS accuracy: <150m (mit Trust-Penalty >50m)
3. Locality Lock bei Votes
4. Trust-gewichtete Votes
5. Voter-Accountability
6. First-Mover Delayed Reward (nach Bestätigung)
7. Provisional Status: 24h als "unverified" sichtbar
8. Phase 3: Android SafetyNet / iOS DeviceCheck

## Cold-Start Lösung (FINAL)
- Silent Consensus: 72h = auto_verified (kein Vote nötig)
- Seed-Submissions: Core-Team bootstrap vor Launch
  (500-1000 verifizierte Preise EU-Hauptstädte)
- First-Mover Reward: sofort nach Tx-Confirmation
- App hat Wert ab User #1

## Contract-Sicherheit (FINAL)
- Proxy-Pattern: EIP-1967 (Transparent Proxy)
- Upgrade: Timelock 48h + 3-of-5 Multisig
- Pausable: Multisig kann pause() bei Exploit
- ReentrancyGuard: alle claim/transfer Funktionen
- Checks-Effects-Interactions: credits=0 VOR transfer
- Race Condition First-Mover: nur mapping check
  (erster im Block gewinnt, atomar)
- Block-Reorg: Client pollt 3 Confirmations

## Rechtliches (FINAL)
- DSGVO: Nullifier-Pattern = keine personenbeziehbaren
  Daten → DSGVO-konform
- MiCA: IFR als Utility Token (Lock-to-Access Modell)
- Rechtsgutachten: vor Launch (EU Crypto + DSGVO)
- Store-Daten: NIEMALS on-chain (nur GPS-Koordinaten)
- Google Places: read-only, kein Caching, ToS-konform

## Offene Punkte (FÜR SPÄTER)
- Store-Name Phase 1: manuell oder GPS-auto?
- Wallet-Pflicht oder optional?
- Dienstleistungen: Phase 1 oder 2?
- OTP-Provider: Twilio / WhatsApp / Telegram?
- Estland e-Residency für spätere EU-Skalierung
- Rechtsgutachten beauftragen (wann?)
