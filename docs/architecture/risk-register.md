# Vendeta — Risk Register (Stand 2026-03-17)

## Kritische Risiken (gelöst)
| # | Risiko | Lösung | Status |
|---|---|---|---|
| R01 | Contract nicht upgradeable | EIP-1967 Proxy | ✅ Gelöst |
| R02 | First-Mover Race Condition | Atomic mapping check | ✅ Gelöst |
| R03 | Trust-Kartell Angriff | Locality Lock + Weighted Votes | ✅ Gelöst |
| R04 | Identitätsverlust bei Handywechsel | Nullifier + Seed Phrase | ✅ Gelöst |
| R05 | Cold-Start kein Consensus | Silent Consensus 72h | ✅ Gelöst |
| R06 | Reentrancy in VendClaim | CEI Pattern + ReentrancyGuard | ✅ Gelöst |
| R07 | DSGVO Phone-Hash | Nullifier-Pattern | ✅ Gelöst |
| R08 | Google ToS Store-Daten | Nur Koordinaten on-chain | ✅ Gelöst |

## Hohe Risiken (gelöst oder mitigiert)
| # | Risiko | Lösung | Status |
|---|---|---|---|
| R09 | The Graph Indexing Delay (TOCTOU) | Optimistic UI + lokaler Cache | ✅ Mitigiert |
| R10 | Geohash-Grenzeffekt | Multi-Cell 9-Nachbar Query | ✅ Gelöst |
| R11 | IFR PartnerVault Erschöpfung | Dynamische Rate + Revenue-Loop | ⚠️ Phase 3 |
| R12 | Self-Vote Sybil | Contract-Regel user_hash check | ✅ Gelöst |
| R13 | Indoor GPS ungenau | 150m Limit + Trust-Penalty | ✅ Mitigiert |
| R14 | First-Mover Race-to-Submit | Delayed Reward nach Bestätigung | ✅ Gelöst |
| R15 | Contract Pausierbarkeit | Pausable + Multisig | ✅ Gelöst |

## Offen / Akzeptiert
| # | Risiko | Plan | Status |
|---|---|---|---|
| R16 | USA SEC Token-Problem | Geo-Block USA Phase 1 | 📋 Phase 3 |
| R17 | Credits/IFR Conversion unklar | UI zeigt Rate vor Claim | ⚠️ UX |
| R18 | APK-Größe Flutter+Rust | AAB + split-per-abi | 📋 Vor Launch |
| R19 | Rechtsgutachten EU | Beauftragen vor Launch | 📋 TODO |
| R20 | Trust Recovery von 0 | +1/Tag Mechanismus | ✅ Gelöst |
| R21 | Block-Reorg Tx verschwindet | 3 Confirmations warten | ✅ Mitigiert |
| R22 | Offline-Submission | Phase 2 lokale Queue | 📋 Phase 2 |
