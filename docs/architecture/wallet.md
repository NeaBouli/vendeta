# Vendetta Wallet — Architektur

## Konzept: Ein Seed für alles

Die Vendetta App erstellt beim ersten Start automatisch
eine HD-Wallet. Der User muss NICHTS konfigurieren.
Der gleiche 12-Wort Seed Phrase dient als:
- ETH/IFR Wallet (BIP44)
- Vendetta Identität (Nullifier)

```
Seed Phrase (12 Wörter, BIP39, 128 bit Entropy)
│
├── BIP44 Derivation: m/44'/60'/0'/0/0
│   └── ETH Private Key → Address
│       ├── ETH Balance (Mainnet)
│       ├── IFR Balance (ERC-20, Mainnet)
│       ├── Base L2 Balance (für Gas)
│       └── Uniswap V2: ETH ↔ IFR Swap
│
└── Nullifier Ableitung:
    nullifier = BIP39_entropy_bytes (128 bit)
    device_salt = SecureEnclave::random()
    user_hash = SHA256(nullifier || device_salt)
    → Vendetta On-Chain Identität
```

## Auto-Setup beim ersten Start

```
App startet erstmalig:

Rust FFI: entropy = OsRng::fill_bytes(16)
Rust FFI: seed_phrase = bip39::encode(entropy)
Rust FFI: private_key = bip44_derive(entropy, "m/44'/60'/0'/0/0")
Rust FFI: eth_address = private_key.to_address()
Rust FFI: user_hash = SHA256(entropy || device_salt)
Flutter: seed_phrase → iOS Keychain / Android Keystore
Flutter: eth_address + user_hash → SecureStorage
UI: "Wallet erstellt! ✓" → optional Seed anzeigen
```

## Wallet UI (Minimal, 3 Tabs)

### Tab 1: Übersicht
- ETH Balance (groß, zentriert)
- IFR Balance
- Wallet-Adresse (gekürzt, tap to copy)
- QR-Code zum Empfangen
- Letzten 5 Transaktionen

### Tab 2: Senden / Empfangen
- Senden: Adresse + Betrag + Token wählen (ETH/IFR)
  → Gas Schätzung anzeigen
  → Bestätigung mit Fingerprint/FaceID
- Empfangen: QR-Code + Adresse

### Tab 3: Swap (ETH ↔ IFR)
- Von/Zu (ETH ↔ IFR)
- Betrag eingeben → Quote von Uniswap V2
- Slippage: 0.5% default
- "Swap" Button → Fingerprint → TX senden
- Uniswap V2 IFR/ETH Pool: bereits live

## Technischer Stack

| Komponente | Technologie | Begründung |
|---|---|---|
| Key Derivation | Rust (bip39, bip32, k256) | Sicherheit, FFI |
| ETH Signing | Rust (ethers-rs lite) | Keine JS-Abhängigkeit |
| Balance/History | Alchemy API (Dart) | Einfachste Integration |
| ERC-20 Calls | web3dart (Flutter) | Nativer Dart Support |
| Swap Quote | Uniswap V2 Router | IFR Pool existiert |
| Key Storage | Flutter Secure Storage | iOS Keychain + Android Keystore |

## Sicherheit

- Private Key NIEMALS im Klartext gespeichert
- Key nur im Speicher während Transaktion
- Biometrie-Gate vor jeder TX-Signierung
- Seed Phrase nur auf expliziten User-Wunsch anzeigen
- Keine externe Wallet nötig (kein MetaMask, kein WalletConnect Phase 1)

## IFR Contract Adressen (ETH Mainnet)

```
InfernoToken:  0x77e99917Eca8539c62F509ED1193ac36580A6e7B
IFRLock:       0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb
PartnerVault:  0xc6eb7714bCb035ebc2D4d9ba7B3762ef7B9d4F7D
```

## Neue Cargo Dependencies (core/Cargo.toml)

```toml
bip39  = "2.0"    # Mnemonic generation + encoding
bip32  = "0.5"    # HD key derivation
k256   = "0.13"   # secp256k1 (ETH key ops)
tiny-keccak = { version = "2.0", features = ["keccak"] }
```

## Rollout

- Phase 1 (MVP): Anzeige ETH + IFR Balance, Empfangen
- Phase 2: Senden ETH + IFR
- Phase 3: Swap ETH ↔ IFR (Uniswap V2)
- Phase 4: Transaction History vollständig
- Phase 5: Base L2 Balance (für Gas-Anzeige)
