# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| main branch | ✅ Active |
| Testnet contracts | ✅ Active |
| Mainnet contracts | ⏳ Not yet deployed |

## Reporting a Vulnerability

**Do NOT open a public issue for security vulnerabilities.**

Instead, please report them privately:

1. **Email:** security@ifrunit.tech
2. **GitHub:** Use the [private vulnerability reporting](https://github.com/NeaBouli/vendeta/security/advisories/new) feature

### What to include

- Description of the vulnerability
- Steps to reproduce
- Affected component (contracts, core, mobile, subgraph)
- Potential impact assessment

### Response Times

| Severity | Response | Fix |
|---|---|---|
| Critical | 24 hours | 48 hours |
| High | 48 hours | 1 week |
| Medium | 1 week | 2 weeks |
| Low | 2 weeks | Next release |

## Security Measures

- All smart contracts audited with Slither (0 High/Medium findings)
- UUPS upgradeable proxy pattern with owner-only upgrade
- No private keys stored in repository
- Nullifier pattern for user privacy (GDPR compliant)
- BIP39/BIP44 HD wallet with platform secure storage

## Scope

In scope:
- Smart contracts (`contracts/src/`)
- Rust core library (`core/`)
- Subgraph mappings (`subgraph/`)
- Mobile app security (`mobile/`)

Out of scope:
- Third-party dependencies (report upstream)
- Social engineering attacks
- DoS attacks on public testnet
