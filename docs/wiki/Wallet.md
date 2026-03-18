# Wallet Architecture

## One Seed for Everything

The Vendetta app automatically creates an HD wallet on first launch. The user sees nothing — just a welcome screen.

The same 12-word seed phrase serves as:
- ETH/IFR wallet (BIP44 m/44'/60'/0'/0/0)
- Vendetta identity (Nullifier Pattern)

## Auto-Setup (Invisible to User)

```
App starts for first time
→ Rust FFI: 128-bit entropy generated
→ BIP39: 12-word mnemonic created
→ BIP44: ETH private key derived
→ SHA256(entropy + device_salt) = user_hash
→ iOS Keychain / Android Keystore: stored
→ UI: "Ready!" — no mention of keys
```

## Two Modes

| Mode | For | How |
|---|---|---|
| Self-Custody | Power users | BIP39 seed in secure storage |
| Standard | Everyone | Coinbase Smart Wallet (Phase 3) |

## IFR Lock Tiers

| Tier | Lock | Rewards |
|---|---|---|
| FREE | 0 IFR | 0.5× |
| Bronze | 1,000 IFR | 1.0× |
| Silver | 5,000 IFR | 1.25× |
| Gold | 10,000 IFR | 1.5× |
| Platinum | 50,000 IFR | 2.0× |

## Key Security

- Private key NEVER stored in plaintext
- Biometric gate before every transaction
- Seed phrase only shown on explicit request
- iOS Keychain + Android Keystore encryption
