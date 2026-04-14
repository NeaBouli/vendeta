# MIGRATION SECURITY MEMO
## Projekt: Vendetta
## Datum: 14.04.2026

### Was wurde gefixt
- .gitignore: broadcast/ hinzugefuegt
- broadcast/ Deployment-Logs aus Git-Index entfernt (waren tracked)
- .gitleaks.toml erstellt (ETH Private Key, Alchemy, BIP39)
- .github/workflows/security-audit.yml erstellt

### Bei Migration beachten
- [ ] Alchemy API Key (BLOCKED — Key noch nicht vorhanden)
- [ ] Flutter Wallet UI braucht .env Loading-Mechanismus (Dart-seitig)
- [ ] Foundry broadcast/ Logs werden lokal generiert — nie committen
- [ ] Deployer Key nur lokal nutzen, nie auf Server

### Benoetigte ENV-Variablen
- DEPLOYER_PRIVATE_KEY (nur lokal, nie auf Server)
- BASESCAN_API_KEY
- BASE_SEPOLIA_RPC (oder MAINNET_RPC)
- ALCHEMY_API_KEY (BLOCKED — noch nicht vorhanden)

### Was NIE auf den Server darf
- .env (enthaelt Deployer Private Key)
- .env.mainnet
- broadcast/ Deployment-Logs
- Foundry Cache/Artifacts

### Migrations-Reihenfolge
1. Alchemy API Key beschaffen (aktuell BLOCKED)
2. Flutter Wallet UI: .env Loading implementieren
3. Smart Contracts sind bereits deployed (Base Sepolia)
4. Backend/API Deployment nach Alchemy Key
5. Beta-Test Griechenland
