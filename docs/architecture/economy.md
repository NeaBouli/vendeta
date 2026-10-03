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

## IFR Partner-Belohnungen (Stand 2026-10-03)
Keine Einnahmen aus dem IFR PartnerVault einplanen:
- IFR-Partnerbelohnungen sind deaktiviert; Vendetta ist kein registrierter IFR Builder.
- Ein Prozentsatz der gelockten IFR wird nicht ausgezahlt; diese Formel ist verworfen.
- Geplant ist das IFR-Partnermodell: Bewertung in EUR, Auszahlung in IFR nur bei verifizierter Einlösung,
  feste Budgets pro Partner. Der PartnerVault wird nicht nachgefüllt.
- Aktueller Stand: https://ifrunit.tech/wiki/transparency.html

## Gas-Lösung
- Standard: Coinbase Smart Wallet (gasless auf Base L2)
- Advanced: Eigener Paymaster Contract (ERC-4337)
- User zahlt KEINEN Gas für normale Submissions
