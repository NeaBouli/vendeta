# System Audit Report — Vendetta

**Datum:** 2026-04-02
**Commit:** `07c9b92` (fix(wiki): complete GR + IT translations)
**Branch:** main
**Auditor:** Claude Code (Opus 4.6)

---

## Ergebnis-Übersicht

| Komponente | Status | Findings |
|---|---|---|
| Rust Core | WARN | 3 |
| Smart Contracts | PASS | 2 WARN |
| Subgraph | WARN | 3 |
| Flutter App | WARN | 2 |
| Cross-Component Kohärenz | PASS | 1 WARN |
| Security | WARN | 2 |
| Dokumentation | WARN | 1 |
| Live Contracts | PASS | 1 WARN |

**Gesamt: 0 FAIL / 12 WARN / Alle Tests grün**

---

## Phase 1 — Rust Core

### PASS: Tests (36/36 grün)
Alle 36 Unit Tests bestanden. Keine Compilation-Warnings.

### WARN: Clippy (4 Lint-Errors)
`cargo clippy -- -D warnings` schlägt fehl mit 4 Errors:
- `location.rs:23` — 2× `manual_range_contains` (lat/lng Bounds)
- `geohash.rs:66` — `manual_div_ceil`
- `wallet.rs:68` — `needless_borrows_for_generic_args`

**Keine Logik-Bugs**, aber CI mit `-D warnings` würde fehlschlagen.

### PASS: Modul-Kohärenz
Alle 6 Module (`hash`, `ean`, `location`, `geohash`, `currency`, `wallet`) korrekt in `lib.rs` exportiert.
Minor: `decode_geohash_center` nicht über Crate-Root re-exportiert.

### PASS: Kritische Konstanten
- Koordinaten: `×1e6` mit `.round()` ✅
- Preise: immer `u64` Cents mit `.round()` ✅
- IFR: nicht im Rust-Scope (korrekt — lebt im Smart Contract Layer)

### WARN: FFI Bridge = Stub
`vendetta_bridge.dart` ist eine **Stub-Implementierung** ohne echtes FFI:
- `generateHash()` nutzt djb2 statt SHA-256 → **Hash-Mismatch** mit On-Chain
- `validateEan()` akzeptiert Länge 12, Rust nur 8/13
- `encodeGeohash()` gibt immer `'u281z'` zurück
- 4 Rust-Funktionen ohne Dart-Gegenstück: `validate_mnemonic`, `mnemonic_word_count`, `eth_address_from_key`, `bounding_box`

**Bekannter Status** — Bridge-Aufbau ist als Session 10 geplant.

---

## Phase 2 — Smart Contracts

### PASS: Tests (60/60 grün)
Alle 60 Forge Tests bestanden. 10.000 Fuzz-Runs ohne Counterexample.

### PASS: Build
`forge build` kompiliert ohne Errors. 10 Lint-Warnings (Style + false-positive `divide-before-multiply` bei Grid-Snap).

### WARN: Adressen-Kohärenz (Netzwerk-Name)
Alle 4 Proxy-Adressen identisch in `base-sepolia.json` und `subgraph.yaml`.
**Aber:** `base-sepolia.json` sagt `"network": "base-sepolia"`, während `subgraph.yaml` `network: base` deklariert. Klärung vor Mainnet nötig.

### PASS: IFR Decimals = 9
`VendClaim.sol:42` — `IFR_DECIMALS = 9`, drei Inline-Kommentare "not 18!". Kein `1e18` im Code.

### WARN: BPS Denominator
Reward-Multiplikatoren mathematisch korrekt, aber Contract nutzt `BPS_DENOM = 1000` statt der Spec-Notation mit 10000. Dokumentations-Inkonsistenz, kein Logik-Bug.

### PASS: Alle übrigen Checks
- Cooldown: `7 days` = 604800s ✅
- Min Claim: 1000 ✅ (VendRewards + VendClaim)
- Trust Bounds: 500/100/1000 ✅
- Rate Limit: 10/User/Tag ✅
- UUPS: alle 4 Contracts haben `_authorizeUpgrade` + `onlyOwner` ✅
- Reentrancy: CEI-Pattern eingehalten, `nonReentrant` auf allen kritischen Funktionen ✅
- Admin: alle admin Funktionen `onlyOwner`-geschützt ✅
- Interfaces: alle 3 vollständig implementiert ✅

---

## Phase 3 — Subgraph

### PASS: Build
`npx graph build` ohne Errors/Warnings. Alle 4 WASM-Module kompiliert.

### WARN: 4 Solidity Events ohne Handler
Folgende Events werden emittiert aber nicht indiziert:
- `VendTrust.LocalityRecorded`
- `VendRewards.FirstMoverBonusPaid` — **Bonus-Zahlungen unsichtbar im Graph**
- `VendRewards.SilentConsensusPaid` — **Silent-Consensus-Payouts unsichtbar**
- `VendClaim.WalletRegistered`

### WARN: `handleDuplicateDetected` ist toter Code
`DuplicateDetected` feuert vor `SubmissionCreated` in derselben TX → `Submission.load()` gibt immer `null` zurück. Handler tut effektiv nichts.

### PASS: Adressen
Alle 4 echte checksummed Adressen, keine Placeholder.

### PASS: Schema-Typen + AssemblyScript
Alle Typen korrekt. `lat6`/`lng6` als `Int!` (korrekt für `int32`). Kein Type-Mismatch.

---

## Phase 4 — Flutter App

### PASS: `flutter analyze` = 0 Issues

### WARN: 7 Dependencies Major-Version veraltet
`flutter_map` 7→8, `flutter_riverpod` 2→3, `go_router` 14→17, etc.
Transitive Dependency `js` ist **discontinued**.

### WARN: IFR/DeFi-Jargon in UI
`"Via Uniswap V2 · IFR/ETH"` im Swap-Sheet. `IFR` mehrfach in Wallet-Strings.

### PASS: Alle übrigen Checks
- IFR Decimals: konsistent `1e9`, nie `1e18` ✅
- Contract-Adressen: `0x77e99917` und `0x769928` stimmen ✅
- Tier-Multiplikatoren: 0.5/1.0/1.25/1.5/2.0 exakt gleich wie Contract ✅
- Graph-Endpoint: echte Studio-URL ✅
- GPS Accuracy: `<= 150.0m` ✅
- Credit Minimum: 1000 überall konsistent ✅
- Router: alle 4 Tabs mit Routes ✅

---

## Phase 5 — Cross-Component Kohärenz

| Wert | Soll | Ist | Status |
|---|---|---|---|
| IFR Decimals | 9 | 9 (VendClaim.sol) | ✅ |
| Trust Default | 500 | 500 (VendTrust.sol) | ✅ |
| Trust Min | 100 | 100 (VendTrust.sol) | ✅ |
| Trust Max | 1000 | 1000 (VendTrust.sol) | ✅ |
| Base Reward | 100 | 100 (VendRewards.sol) | ✅ |
| Min Claim | 1000 | 1000 (VendClaim.sol + VendRewards.sol + Flutter) | ✅ |
| Cooldown | 604800s | 7 days = 604800 (VendClaim.sol) | ✅ |
| Coord Precision | ×1e6 | ×1e6 + .round() (Rust + Solidity + Dart) | ✅ |
| Geohash | 5 | P5 überall (Rust + Solidity + Subgraph + Flutter) | ✅ |
| First Mover Grid | 150m | LOCATION_SNAP=150000 (Registry + Rewards + Flutter) | ✅ |
| Locality Lock | 7 Tage | LOCALITY_WINDOW = 7 days (VendTrust) | ✅ |
| Consensus Window | 72h | SILENT_CONSENSUS_SECONDS = 72 hours (VendRegistry) | ✅ |
| Rate Limit | 10/Tag | MAX_DAILY_SUBMISSIONS = 10 | ✅ |
| Consensus Verify | 80% | CONSENSUS_VERIFY_BPS = 8000 | ✅ |
| Dispute Threshold | 75% | CONSENSUS_DISPUTE_BPS = 7500 | ✅ |
| First Mover Bonus | 2× | FIRST_MOVER_BPS = 2000 (÷1000) | ✅ |
| Tier FREE | 0.5× | 500 BPS (÷1000 = 0.5) = Dart 0.5 | ✅ |
| Tier BRONZE | 1.0× | 1000 BPS = Dart 1.0 | ✅ |
| Tier SILVER | 1.25× | 1250 BPS = Dart 1.25 | ✅ |
| Tier GOLD | 1.5× | 1500 BPS = Dart 1.5 | ✅ |
| Tier PLATINUM | 2.0× | 2000 BPS = Dart 2.0 | ✅ |

### WARN: Revenue Split 70/20/10
Nur "70/30" in `economy.md` dokumentiert. Die 70/20/10-Aufteilung existiert weder im Code noch in der Dokumentation.

---

## Phase 6 — Security

### PASS: Keine Secrets in Git-History
- Keine Private Keys committed ✅
- Keine API Keys committed ✅
- `.env` nicht tracked ✅

### WARN: BIP39 Test-Mnemonic im Production-Stub
`vendetta_bridge.dart:74` enthält `abandon abandon...about` (bekannter Testvektor).
Kein echtes Secret, aber muss vor Release entfernt werden.

### WARN: security-audit.md Claim ungenau
Dokument behauptet "ReentrancyGuard on all state-mutating functions". Tatsächlich haben 3 Funktionen keinen Guard:
- `VendRegistry.triggerSilentConsensus()`
- `VendTrust.recordRegionVisit()`
- `VendTrust.recoverTrust()`

Alle drei machen keine externen Calls → **kein Reentrancy-Risiko**, aber die Doku sollte korrigiert werden.

### PASS: Owner-Only Admin
Alle admin/pause/upgrade Funktionen `onlyOwner`-geschützt.

---

## Phase 7 — Dokumentation

### WARN: README IFR-Token Link falsch
`README.md:157` — Etherscan-Link für `$IFR` zeigt auf `0x77e99917...` (VendRegistry auf Base Sepolia), nicht auf den IFR Token auf ETH Mainnet.

### PASS: Alle übrigen Docs
- security-audit.md Datum: 2026-03-17 ✅
- Wiki Tier-Zahlen: identisch mit Contract ✅
- Landing Page: Phase 0+1 COMPLETE, Phase 2 ACTIVE ✅
- IFR Builder Registration: alle 4 Adressen korrekt ✅

---

## Phase 8 — Live Contract Smoke Tests

### PASS: VendRegistry
- `totalSubmissions()` = 0 ✅
- `MAX_DAILY_SUBMISSIONS()` = 10 ✅

### PASS: VendTrust
- `DEFAULT_TRUST()` = 500 ✅
- `MIN_TRUST()` = 100 ✅

### PASS: VendRewards
- `BASE_REWARD()` = 100 ✅
- `owner()` = `0x6b36687b...` ✅

### WARN: VendRewards.IFR_DECIMALS()
`IFR_DECIMALS()` auf VendRewards-Adresse gibt Revert zurück. **Korrekt** — `IFR_DECIMALS` ist nur in `VendClaim.sol` definiert, nicht in `VendRewards.sol`.

### PASS: VendClaim
- `MIN_CLAIM_CREDITS()` = 1000 ✅
- `CLAIM_COOLDOWN()` = 604800 ✅
- `IFR_DECIMALS()` = 9 ✅

### PASS: Subgraph
Subgraph antwortet. Block number: `44183072` (aktuell synced).

---

## Empfehlungen

### Vor Beta-Launch (Priorität HOCH)
1. **FFI Bridge aufbauen** — Stub durch echtes `flutter_rust_bridge` ersetzen (Session 10). Hash-Mismatch ist ein Blocker.
2. **Subgraph: 4 fehlende Event-Handler** hinzufügen, insbesondere `FirstMoverBonusPaid` und `SilentConsensusPaid`.
3. **Subgraph: `handleDuplicateDetected`** reparieren (Reihenfolge-Bug).
4. **README IFR-Link** korrigieren (zeigt auf falschen Contract/Chain).

### Vor Mainnet (Priorität MITTEL)
5. **Clippy-Warnings** fixen (4 Errors, alle trivial).
6. **Flutter Dependencies** updaten (7 Major-Versionen zurück).
7. **`subgraph.yaml` Netzwerk** klären: `base` vs `base-sepolia`.
8. **BIP39 Test-Mnemonic** aus Production-Stub entfernen.
9. **security-audit.md** korrigieren: "all state-mutating functions" → präzisieren.

### Nice-to-Have
10. **DeFi-Jargon in UI** überprüfen (Uniswap/ETH sichtbar im Swap-Sheet).
11. **BPS Denominator-Dokumentation** vereinheitlichen (1000 im Code vs 10000 in Spec).
12. **Revenue Split 70/20/10** dokumentieren oder 70/30 bestätigen.

---

## Fazit

**NEEDS FIXES BEFORE PRODUCTION — aber keine kritischen Logik-Bugs.**

Alle 96 Tests grün (36 Rust + 60 Solidity). Alle Cross-Component Kohärenz-Checks bestanden (21/21). Keine Secrets leaked. Keine Reentrancy-Vektoren. Smart Contracts sind solide.

Die Hauptblocker sind:
1. FFI Bridge (Stub → Production)
2. Subgraph Event Coverage (4 Handler fehlen)
3. Dokumentations-Korrekturen (README Link, security-audit.md)

**Testnet-Status: OPERATIONAL** — alle 4 Contracts antworten korrekt, Subgraph synced.
