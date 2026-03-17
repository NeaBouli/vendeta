use sha2::{Sha256, Digest};
use serde::{Deserialize, Serialize};

/// Input data for generating a submission proof hash
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubmissionInput {
    pub ean: String,
    pub price_cents: u64,
    pub lat6: i32,
    pub lng6: i32,
    pub timestamp: u64,
    pub user_hash: String,
}

/// SHA-256 proof hash for a price submission
#[derive(Debug, Clone, PartialEq)]
pub struct SubmissionHash {
    pub bytes: [u8; 32],
}

impl SubmissionHash {
    /// Generate SHA-256 hash from submission input
    /// This is the client-side proof hash anchored on-chain
    pub fn generate(input: &SubmissionInput) -> Self {
        let mut hasher = Sha256::new();
        hasher.update(input.ean.as_bytes());
        hasher.update(input.price_cents.to_le_bytes());
        hasher.update(input.lat6.to_le_bytes());
        hasher.update(input.lng6.to_le_bytes());
        hasher.update(input.timestamp.to_le_bytes());
        hasher.update(input.user_hash.as_bytes());
        let result = hasher.finalize();
        let mut bytes = [0u8; 32];
        bytes.copy_from_slice(&result);
        Self { bytes }
    }

    /// Return hex-encoded hash string
    pub fn to_hex(&self) -> String {
        hex::encode(self.bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_deterministic() {
        let input = SubmissionInput {
            ean: "4006381333931".to_string(),
            price_cents: 79,
            lat6: 48_137_154,
            lng6: 11_576_124,
            timestamp: 1710633600,
            user_hash: "abc123".to_string(),
        };
        let h1 = SubmissionHash::generate(&input);
        let h2 = SubmissionHash::generate(&input);
        assert_eq!(h1, h2);
    }

    #[test]
    fn test_hash_different_price() {
        let mut input = SubmissionInput {
            ean: "4006381333931".to_string(),
            price_cents: 79,
            lat6: 48_137_154,
            lng6: 11_576_124,
            timestamp: 1710633600,
            user_hash: "abc123".to_string(),
        };
        let h1 = SubmissionHash::generate(&input);
        input.price_cents = 89;
        let h2 = SubmissionHash::generate(&input);
        assert_ne!(h1, h2);
    }

    #[test]
    fn test_hash_hex_length() {
        let input = SubmissionInput {
            ean: "4006381333931".to_string(),
            price_cents: 79,
            lat6: 48_137_154,
            lng6: 11_576_124,
            timestamp: 1710633600,
            user_hash: "abc123".to_string(),
        };
        let h = SubmissionHash::generate(&input);
        assert_eq!(h.to_hex().len(), 64); // SHA-256 = 64 hex chars
    }
}
