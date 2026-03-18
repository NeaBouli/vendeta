# Contributing to Vendetta

Thank you for your interest in contributing to Vendetta!

## Getting Started

```bash
git clone https://github.com/NeaBouli/vendeta
cd vendeta
```

### Rust Core
```bash
cd core
cargo test        # 36 tests
```

### Smart Contracts
```bash
cd contracts
forge install
forge test -vv    # 60 tests
```

### Flutter App
```bash
cd mobile
flutter pub get
flutter analyze
```

## Commit Format

```
feat(scope): what was built
fix(scope): what was fixed
docs: documentation only
test: test additions
chore: maintenance
```

Scopes: `core` | `registry` | `trust` | `rewards` | `claim` | `wallet` | `mobile` | `subgraph` | `docs`

## Pull Request Process

1. Fork the repository
2. Create feature branch (`git checkout -b feat/my-feature`)
3. Write tests first (TDD preferred)
4. All tests must pass (`forge test` + `cargo test`)
5. Open PR with clear description

## Code of Conduct

Be respectful. Focus on the code. We're building something useful.

## License

By contributing, you agree your contributions are licensed under the [MIT License](LICENSE).
