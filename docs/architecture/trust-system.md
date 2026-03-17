# Vendeta — Trust & Reward System (Draft)

## Trust Score (0–1000, on-chain)
| Ereignis | Änderung |
|---|---|
| Neuer User | 500 (default) |
| Submission bestätigt (3+ votes) | +5 |
| Korrekter Community-Vote | +2 |
| 4:1 Consensus gegen Submission | −50 |
| Reward-Multiplier | trust ÷ 1000 |

## Reward-Szenarien
| Szenario | Credits |
|---|---|
| First Mover (neues EAN + Ort) | 200 (2× bonus) |
| 2. Submission selber Ort+EAN | 50 (÷2) |
| 3. Submission (Duplikat) | 33 (÷3) |
| 10. Submission | 10 (÷10) |
| IFR Premium (isLocked=true) | +20% auf alles |
| Trust 0 | 0 Credits |

## Consensus-Regel
- Minimum 3 Votes für Consensus-Wirkung
- 4:1 Mehrheit → Verlierer −50 Trust
- 2:2 Gleichstand → kein Trust-Verlust, Status "unverified"
- Unter 3 Votes → Status "low_confidence"

## Anti-Gaming
1. Rate Limit on-chain: max 10 Submissions/user/location/Tag
2. GPS accuracy check: <50m required (client-side)
3. Reputation Weight: neue User 0.5× Multiplier
4. Community Consensus: 4:1 = Trust-Verlust
5. Trust kann 0 erreichen → Rewards = 0 → kein Anreiz
6. Phase 3: Device Attestation (Android SafetyNet / iOS DeviceCheck)
