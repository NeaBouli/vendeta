# Vendetta — Offene Fragen (Aktuell)

## Entschieden ✅
- [x] Kein eigener Token → IFR
- [x] Kein eigener Server → The Graph + Railway OTP
- [x] Base L2 für Contracts
- [x] Flutter + Rust FFI (flutter_rust_bridge)
- [x] Geohash Precision 5 + Multi-Cell Query
- [x] Koordinaten als int32 (×1e6) mit .round()
- [x] Hash: Nullifier-Pattern (nicht HMAC-phone)
- [x] 12-Wort Seed Phrase für Recovery
- [x] Google Places read-only, Store NICHT on-chain
- [x] Silent Consensus 72h (Cold-Start-Lösung)
- [x] Trust-gewichtete Votes + Locality Lock
- [x] Proxy-Pattern (EIP-1967) für alle Contracts
- [x] ISO 4217 Währungs-Code on-chain (bytes3)
- [x] Rollout: Europa Phase 1
- [x] Unternehmensstruktur: Griechenland vorhanden
- [x] First-Mover Reward: delayed nach 1. Bestätigung
- [x] GPS Limit: 150m (mit Trust-Penalty >50m)

## Noch offen (Core Dev Entscheidung nötig)
- [ ] Store-Name Phase 1: manuell eingeben ODER
      automatisch via GPS+OSM Nominatim?
- [ ] Wallet Phase 1: Pflicht oder optional?
      (optional = Suchen möglich, keine Rewards)
- [ ] Dienstleistungen (Friseur, Handwerker):
      Phase 1 oder Phase 2?
- [ ] OTP-Provider: Twilio, WhatsApp oder Telegram?
- [ ] Seed-Submissions vor Launch: Wer macht das?
      Wie viele Städte? Welche Kategorien?
- [ ] Minimum Trust für Votes: aktuell 0 (jeder darf
      voten) — oder Minimum 200 Trust?

## Technische Todos (vor Code)
- [ ] Rechtsgutachten EU: DSGVO + MiCA beauftragen
- [ ] IFR Builder-Registrierung anstoßen
      (GitHub Issue: NeaBouli/inferno builder-registry.yml)
- [ ] The Graph: dezentrales Netzwerk Account anlegen
- [ ] Base L2 Testnet (Sepolia): Wallet einrichten
