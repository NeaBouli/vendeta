use serde::{Deserialize, Serialize};

/// ISO 4217 Currency Codes (Europa Phase 1)
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum CurrencyCode {
    EUR, // Euro (primär)
    GBP, // British Pound
    CHF, // Swiss Franc
    PLN, // Polish Zloty
    CZK, // Czech Koruna
    HUF, // Hungarian Forint
    RON, // Romanian Leu
    SEK, // Swedish Krona
    NOK, // Norwegian Krone
    DKK, // Danish Krone
}

impl CurrencyCode {
    /// Number of decimal places for this currency
    /// EUR: 2 (0.79 EUR = 79 cents)
    /// HUF: 0 (no decimals used in practice)
    pub fn decimals(&self) -> u8 {
        match self {
            CurrencyCode::HUF => 0,
            _ => 2,
        }
    }

    /// Convert to on-chain bytes3 representation
    pub fn to_bytes3(&self) -> [u8; 3] {
        match self {
            CurrencyCode::EUR => *b"EUR",
            CurrencyCode::GBP => *b"GBP",
            CurrencyCode::CHF => *b"CHF",
            CurrencyCode::PLN => *b"PLN",
            CurrencyCode::CZK => *b"CZK",
            CurrencyCode::HUF => *b"HUF",
            CurrencyCode::RON => *b"RON",
            CurrencyCode::SEK => *b"SEK",
            CurrencyCode::NOK => *b"NOK",
            CurrencyCode::DKK => *b"DKK",
        }
    }

    pub fn from_bytes3(b: &[u8; 3]) -> Option<Self> {
        match b {
            b"EUR" => Some(Self::EUR),
            b"GBP" => Some(Self::GBP),
            b"CHF" => Some(Self::CHF),
            b"PLN" => Some(Self::PLN),
            b"CZK" => Some(Self::CZK),
            b"HUF" => Some(Self::HUF),
            b"RON" => Some(Self::RON),
            b"SEK" => Some(Self::SEK),
            b"NOK" => Some(Self::NOK),
            b"DKK" => Some(Self::DKK),
            _ => None,
        }
    }
}

/// Convert float price to integer cents
/// ALWAYS use .round() to avoid float truncation bugs
pub fn price_to_cents(price: f64, currency: CurrencyCode) -> u64 {
    let factor = 10_u64.pow(currency.decimals() as u32) as f64;
    (price * factor).round() as u64
}

/// Convert cents back to display string
pub fn cents_to_display(cents: u64, currency: CurrencyCode) -> String {
    let decimals = currency.decimals();
    if decimals == 0 {
        return format!("{}", cents);
    }
    let factor = 10_u64.pow(decimals as u32);
    let major = cents / factor;
    let minor = cents % factor;
    format!("{}.{:0>width$}", major, minor, width = decimals as usize)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_eur_cents() {
        assert_eq!(price_to_cents(0.79, CurrencyCode::EUR), 79);
        assert_eq!(price_to_cents(1.99, CurrencyCode::EUR), 199);
        assert_eq!(price_to_cents(10.00, CurrencyCode::EUR), 1000);
    }

    #[test]
    fn test_no_float_truncation() {
        // Classic float trap: 1.49 * 100 = 148.99999...
        // Must round to 149, not truncate to 148
        assert_eq!(price_to_cents(1.49, CurrencyCode::EUR), 149);
        assert_eq!(price_to_cents(2.99, CurrencyCode::EUR), 299);
        assert_eq!(price_to_cents(0.10, CurrencyCode::EUR), 10);
    }

    #[test]
    fn test_huf_no_decimals() {
        assert_eq!(price_to_cents(850.0, CurrencyCode::HUF), 850);
    }

    #[test]
    fn test_display_roundtrip() {
        let cents = price_to_cents(1.99, CurrencyCode::EUR);
        let display = cents_to_display(cents, CurrencyCode::EUR);
        assert_eq!(display, "1.99");
    }

    #[test]
    fn test_bytes3_roundtrip() {
        let eur = CurrencyCode::EUR;
        let b = eur.to_bytes3();
        let back = CurrencyCode::from_bytes3(&b).unwrap();
        assert_eq!(eur, back);
    }
}
