# Vendeta — Offene Fragen (Stand 2026-03-17)

## Noch zu entscheiden (Core Dev Input nötig)

- [ ] Store-Name Phase 1: manuell eingeben ODER
      automatisch via Google Places aus GPS?
- [ ] Dienstleistungen (Friseur, Handwerker) in Phase 1
      oder erst Phase 2?
- [ ] Wallet-Pflicht oder optional?
      (kein Wallet = keine Credits, aber Suche möglich?)
- [ ] IFR Builder-Registrierung: wann anstoßen?
      (GitHub Issue auf NeaBouli/inferno)
- [ ] Minimum Claim-Betrag für IFR: 1000 Credits ok?
- [ ] OTP via Railway: Twilio oder anderer SMS-Provider?
- [ ] The Graph: hosted service (einfach) oder
      dezentrales Netzwerk (günstiger, komplexer)?
- [ ] Offline-Mode: Phase 1 ohne (einfacher) oder
      mit lokaler Queue (Phase 3)?

## Bestätigte Entscheidungen
- [x] Kein eigener Token → IFR
- [x] Kein eigener Server → The Graph + Railway (OTP only)
- [x] Base L2 für Contracts
- [x] Flutter + Rust FFI
- [x] Geohash Precision 5
- [x] Koordinaten als int32 (×1e6), kein Float on-chain
- [x] Hash generiert client-side (Rust FFI)
- [x] Phone-Hash: HMAC-SHA256(phone, device_id), Nummer nie gespeichert
- [x] Google Places read-only, Store-Daten NICHT on-chain
