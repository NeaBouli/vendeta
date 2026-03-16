# Vendeta — Masterplan

## Kern-Vision
Vendeta ist ein dezentrales Consumer-Intelligence-Netzwerk.
Nutzer fotografieren oder scannen Preise im Alltag (Supermarkt,
Tankstelle, Restaurant, Handwerker etc.). Die Daten werden mit
GPS-Koordinate, Zeitstempel und SHA-256-Hash auf der Blockchain
verankert. Andere Nutzer suchen in ihrer Nähe nach günstigen
Preisen. Teilnahme wird mit IFR-Token-Credits belohnt.

## Problem
- Preise steigen überall. Konsumenten haben keine Transparenz.
- Händler können wuchern ohne Konsequenzen.
- Es gibt kein dezentrales, community-getriebenes Preisnetzwerk.

## Lösung
- Open-Source Karte (MapLibre + OpenStreetMap)
- User scannt EAN-Code oder fotografiert Preisschild
- GPS-Koordinate + Preis + Timestamp → SHA-256 Hash → Blockchain
- Andere User suchen: "Wo ist Produkt X am günstigsten in 5km?"
- Reward: IFR-Credits für valide Submissions → on-chain claimbar

## Token-Strategie
- KEIN eigener Token. Reward-Token ist IFR (ifrunit.tech)
- Off-chain Credit-Ledger für Mikro-Rewards (kein Gas pro Submission)
- Wöchentlicher On-chain Claim via VendClaim.sol (Base L2)
- Premium-Features: IFR Lock Check via isLocked() Builder API
- Vendeta ist offizieller IFR Builder (PartnerVault Allocation)

## Blockchain-Strategie
- Hash-Anchoring: Base L2 (EVM, günstig, Coinbase-backed)
- IFR Lock Verification: Ethereum Mainnet (via IFR Builder API)
- Warum Base L2: EVM-kompatibel, ~$0.001/Tx, Smart Wallet Onboarding
- Warum nicht Solana: kein EVM, IFR-Bridge zu komplex für MVP

## Anti-Gaming
- Rate Limit: max 10 Submissions / Location / Tag / User
- GPS-Proof: Submission nur mit echtem GPS-Signal
- AI-Plausibility: Preis gegen historische Daten + Kategorie geprüft
- Community-Voting: 3+ Bestätigungen = Bonus-Credits
- Reputation Score: neue User = weniger Credits, etablierte = mehr

## Tech Stack
| Schicht          | Technologie                        |
|------------------|------------------------------------|
| Core Library     | Rust                               |
| Backend API      | Rust + Axum                        |
| Datenbank        | PostgreSQL + PostGIS (Geo-Suche)   |
| Cache            | Redis                              |
| Mobile App       | Flutter (Android + iOS)            |
| Maps             | MapLibre + OpenStreetMap           |
| Smart Contracts  | Solidity (Base L2)                 |
| Token / Rewards  | IFR — ifrunit.tech                 |
| AI               | Cloud (Phase 2), On-Device (Phase 3)|

## Phasen

### Phase 0 — Setup & Architektur ← WIR SIND HIER
- [x] Konzept definiert
- [x] Tech-Stack entschieden
- [x] Blockchain-Strategie festgelegt
- [x] Architektur designed
- [ ] Repo-Struktur komplett aufgesetzt
- [ ] Living Documentation Dashboard live

### Phase 1 — Core & Backend (Rust)
- [ ] Rust Core Library: hash.rs, ean.rs, location.rs
- [ ] Docker Compose: PostgreSQL+PostGIS, Redis
- [ ] Axum REST API: POST /submit, GET /search
- [ ] Unit Tests für alle Core-Funktionen

### Phase 2 — Mobile MVP (Flutter)
- [ ] Flutter Projekt Setup
- [ ] MapLibre Karte + Radius-Suche
- [ ] Kamera + EAN-Barcode Scanner
- [ ] Preis-Submission Flow
- [ ] IFR Credits Dashboard

### Phase 3 — Blockchain Integration
- [ ] VendSubmit.sol (Base L2 Hash-Anchoring)
- [ ] VendClaim.sol (IFR Credit Claim)
- [ ] IFR Lock Check (isLocked() Builder API)
- [ ] Off-chain Credit Ledger im Backend

### Phase 4 — AI + Verification
- [ ] Produkt-Erkennung aus Foto (Cloud AI)
- [ ] Preis-Plausibilitäts-Check
- [ ] Community-Voting System
- [ ] Reputation Score System

### Phase 5 — Scale & DAO
- [ ] On-Device AI (Privacy-first)
- [ ] IFR DAO Governance Integration
- [ ] Builder-Registry auf ifrunit.tech
- [ ] App Store + Google Play Launch

## Arbeitsregeln (Claude Code Protokoll)
1. Modular — kein Modul importiert ein anderes direkt (nur über Interfaces)
2. Rust für alles was Performance + Security braucht
3. Kein eigener Token — IFR ist das einzige Reward-Token
4. docs/index.html wird nach JEDEM abgeschlossenen Task aktualisiert
5. Kein Commit ohne verifizierten Stand (cargo check, Browser-Test)
6. Jede Rust-Funktion bekommt einen Unit Test
7. Commits folgen Conventional Commits Format
