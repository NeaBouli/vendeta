# Vendetta Wirtschaftsmodell

## Wie User IFR bekommen
1. VERDIENEN: Credits durch Submissions → VendClaim → IFR
2. KAUFEN: ETH → IFR via Uniswap V2 (in App)
3. BOOTSTRAP: ifrunit.tech/wiki/bootstrap.html

## Tier-System (IFR Lock basiert)

| Tier | IFR Lock | Reward-Multiplier | Trust-Bonus |
|---|---|---|---|
| FREE | 0 IFR | 0.5× | — |
| BRONZE | 1.000 IFR | 1.0× | +50 |
| SILVER | 5.000 IFR | 1.25× | +100 |
| GOLD | 10.000 IFR | 1.5× | +200 |
| PLATINUM | 50.000 IFR | 2.0× | +300 |

Wenn Lock fällt → Tier fällt SOFORT (isLocked() check)

## Finale Reward-Formel

```
reward = BASE(100) × (trust/1000) × tier_mult
         × first_mover_bonus ÷ dup_count
```

## Werbemodul (Phase 3)

| Format | Modell | Beschreibung |
|---|---|---|
| Gesponserte Suchergebnisse | CPC | Händler zahlt pro Klick |
| Verifizierter Händler-Pin | CPM | Pin auf Karte, pro 1000 Views |
| "Deal der Woche" | Flat/Woche | Highlight-Platzierung |

REGEL: Alle Werbepreise müssen on-chain als
Submission existieren → keine Lockpreise möglich

Revenue-Kreislauf: 70% Vendetta / 30% IFR-Kauf
→ Kauf erhöht IFR-Wert → Rewards wertvoller

## IFR Builder Revenue
Wenn User IFR für Vendetta lockt:
Vendetta verdient 10-20% aus PartnerVault (40M IFR)
Beispiel: 10.000 User × 1.000 IFR × 15% = 1.5M IFR

## Gas-Lösung
- Standard: Coinbase Smart Wallet (gasless auf Base L2)
- Advanced: Eigener Paymaster Contract (ERC-4337)
- User zahlt KEINEN Gas für normale Submissions
