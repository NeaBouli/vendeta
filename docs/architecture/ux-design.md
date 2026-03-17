# Vendetta UX Design — Nicht-Crypto-User First

## Eiserne Regel: Kein Crypto-Jargon im Basis-UI

VERBOTEN in der normalen App-Oberfläche:
- Wallet, Blockchain, Token, Gas, Transaction
- Private Key, Seed Phrase, Hash, IFR (außer Wallet-Tab)

ERLAUBT:
- Credits, Punkte, Belohnung, Gespeichert
- Verifiziert, Gesperrt, Auszahlen

## Onboarding (4 Screens, 2 Minuten)
1. Willkommen → "Loslegen"
2. Telefon bestätigen (SMS OTP) — Hintergrund: Nullifier
3. GPS erlauben — Standard System-Dialog
4. Fertig! → Karte öffnet sich
→ KEIN Mention von Blockchain, Wallet, Keys

## Submission Flow (User-Sicht)
1. Barcode scannen → Preis eingeben → "Speichern"
2. Ladebalken "Wird gespeichert..."
3. "+ 50 Credits verdient!" — fertig
→ Gas, TX, Hash: UNSICHTBAR

## Wallet — Zwei Modi

### Modus A (Standard/Einsteiger):
- Coinbase Smart Wallet (Base L2)
- E-Mail oder Google/Apple Login
- Gasless Transactions (kein ETH nötig)
- Kein Seed Phrase für normale Nutzung

### Modus B (Selbstverwaltet/Fortgeschrittene):
- BIP39 Seed (12 Wörter) in Einstellungen
- BIP44 Key Derivation (Rust FFI)
- Volle Kontrolle, volle Verantwortung

## Auszahlen Flow
1. User drückt "Auszahlen" (ab 1.000 Credits)
2. Einmalig: einfache Erklärung was IFR ist
3. Fingerprint/Face ID
4. Automatisch: VendClaim → Bridge → IFR in Wallet
5. "Du hast X IFR erhalten!" — fertig

## IFR Sperren für mehr Rewards
1. Tier-Auswahl (visuell, ohne IFR-Mengen)
   "Starter / Aktiv / Power" statt "1.000/5.000/10.000 IFR"
2. Wenn nicht genug IFR: "Kaufen?" → ETH→IFR Swap
3. Approve + Lock automatisch in einer Transaktion
4. "Gesperrt! Du verdienst jetzt X% mehr Credits."
