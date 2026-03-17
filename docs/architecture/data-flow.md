# Vendeta — Datenfluss (Draft)

## Submission Flow (Preis melden)

```
GPS prüfen (Rust FFI)
└─ Coordinates::new() + accuracy <50m
└─ Kein GPS = kein Submit
EAN scannen (Kamera → Rust FFI)
└─ EanCode::parse() lokal
└─ Ungültig = sofortiges Feedback, kein Network
Store erkennen
└─ Google Places API (client-key, read-only)
└─ Store-Name nur lokal angezeigt, NICHT on-chain
Hash generieren (Rust FFI)
└─ SubmissionHash::generate(ean, price_cents, lat6, lng6, ts, user_hash)
└─ Lokal, instant, SHA-256
└─ WICHTIG: Server generiert NICHT — Client ist source of truth
Pre-Check Duplikat (The Graph)
└─ hashExists("0x...") → true/false
└─ User wird gewarnt + Reward-Info angezeigt
VendRegistry.submit() — Base L2
└─ hash, ean_hash, price_cents, lat6, lng6, geohash5, user_hash
└─ Contract prüft: hashExists? → revert wenn ja
└─ Contract prüft: locationHasEan(±10m)? → firstMover flag
└─ Emits: SubmissionCreated(hash, ean_hash, price_cents, lat6, lng6, user_hash, firstMover)
VendRewards Berechnung (on-chain)
└─ reward = base(100) × trust_mult × firstMover_bonus ÷ dup_count
└─ Emits: RewardEarned(user_hash, amount)
The Graph indiziert Events
└─ SubmissionCreated → sofort suchbar
└─ Latenz: ~10s bis Event indiziert
```

## Search Flow (Produkt suchen)

```
User gibt Suchbegriff oder EAN ein
Geohash aus GPS berechnen (Rust FFI, lokal)
The Graph GraphQL Query:
  submissions(where: {
    geohash5_starts_with: "u284",  ← Region
    ean_hash: "0x...",             ← optional
    name_contains: "milka"         ← optional
  }) → <50ms
Client filtert mit Haversine (Rust FFI) für exakten Radius
Ergebnisse auf MapLibre anzeigen
```

## Identity Flow (einmalig, Erststart)

```
User gibt Telefonnummer ein (UI, client-only)
Rust FFI: user_hash = HMAC-SHA256(phone_e164, device_fingerprint)
Nummer wird NICHT gespeichert
Optional OTP via Railway (stateless):
└─ Railway sendet SMS → User gibt OTP ein → session_token (1h TTL)
└─ Railway speichert NICHTS
user_hash on-chain = einziger Identifier
Device fingerprint verhindert Multi-Account (Sybil)
```
