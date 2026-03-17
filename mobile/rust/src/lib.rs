pub use vendeta_core::{
    SubmissionHash, SubmissionInput,
    EanCode, EanError, BarcodeFormat,
    Coordinates,
    GeohashPrecision, CurrencyCode,
    encode_geohash, geohash_neighbors,
    distance_meters, price_to_cents, cents_to_display,
};

/// Generate SHA-256 proof hash for a submission
pub fn generate_hash(
    ean: &str, price_cents: u64,
    lat: f64, lng: f64,
    timestamp: u64, user_hash: &str,
) -> String {
    let input = SubmissionInput {
        ean: ean.to_string(),
        price_cents,
        lat6: (lat * 1_000_000.0).round() as i32,
        lng6: (lng * 1_000_000.0).round() as i32,
        timestamp,
        user_hash: user_hash.to_string(),
    };
    SubmissionHash::generate(&input).to_hex()
}

/// Validate EAN barcode
pub fn validate_ean(ean: &str) -> bool {
    EanCode::parse(ean).is_ok()
}

/// Convert lat/lng to int32 for on-chain storage
pub fn lat_to_int32(lat: f64) -> i32 {
    (lat * 1_000_000.0_f64).round() as i32
}

pub fn lng_to_int32(lng: f64) -> i32 {
    (lng * 1_000_000.0_f64).round() as i32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_hash() {
        let h = generate_hash("4006381333931", 79, 48.137, 11.576, 1710633600, "abc");
        assert_eq!(h.len(), 64);
    }

    #[test]
    fn test_validate_ean() {
        assert!(validate_ean("4006381333931"));
        assert!(!validate_ean("123"));
    }
}
