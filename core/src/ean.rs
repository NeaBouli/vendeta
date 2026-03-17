use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum EanError {
    InvalidLength(usize),
    NonNumeric,
    InvalidCheckDigit,
}

impl fmt::Display for EanError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EanError::InvalidLength(len) => {
                write!(f, "Invalid EAN length: {} (expected 8 or 13)", len)
            }
            EanError::NonNumeric => write!(f, "EAN contains non-numeric characters"),
            EanError::InvalidCheckDigit => write!(f, "Invalid EAN check digit"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum BarcodeFormat {
    EAN8,
    EAN13,
}

/// Validated EAN barcode
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EanCode {
    pub code: String,
    pub format: BarcodeFormat,
}

impl EanCode {
    /// Parse and validate an EAN barcode string
    pub fn parse(input: &str) -> Result<Self, EanError> {
        let trimmed = input.trim();

        if !trimmed.chars().all(|c| c.is_ascii_digit()) {
            return Err(EanError::NonNumeric);
        }

        let format = match trimmed.len() {
            8 => BarcodeFormat::EAN8,
            13 => BarcodeFormat::EAN13,
            len => return Err(EanError::InvalidLength(len)),
        };

        if !Self::valid_check_digit(trimmed) {
            return Err(EanError::InvalidCheckDigit);
        }

        Ok(Self {
            code: trimmed.to_string(),
            format,
        })
    }

    /// Validate EAN check digit (last digit)
    fn valid_check_digit(code: &str) -> bool {
        let digits: Vec<u32> = code.chars().filter_map(|c| c.to_digit(10)).collect();
        if digits.len() != code.len() {
            return false;
        }

        let check_len = digits.len() - 1;
        let mut sum = 0u32;
        for (i, &d) in digits[..check_len].iter().enumerate() {
            if i % 2 == 0 {
                sum += d;
            } else {
                sum += d * 3;
            }
        }
        let expected = (10 - (sum % 10)) % 10;
        digits[check_len] == expected
    }

    /// Generate keccak256-compatible hash of the EAN for on-chain use
    pub fn to_hash_bytes(&self) -> Vec<u8> {
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(self.code.as_bytes());
        hasher.finalize().to_vec()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_ean13() {
        let ean = EanCode::parse("4006381333931").unwrap();
        assert_eq!(ean.format, BarcodeFormat::EAN13);
        assert_eq!(ean.code, "4006381333931");
    }

    #[test]
    fn test_valid_ean8() {
        let ean = EanCode::parse("96385074").unwrap();
        assert_eq!(ean.format, BarcodeFormat::EAN8);
    }

    #[test]
    fn test_invalid_check_digit() {
        let result = EanCode::parse("4006381333932"); // wrong check
        assert!(matches!(result, Err(EanError::InvalidCheckDigit)));
    }

    #[test]
    fn test_invalid_length() {
        let result = EanCode::parse("12345");
        assert!(matches!(result, Err(EanError::InvalidLength(5))));
    }

    #[test]
    fn test_non_numeric() {
        let result = EanCode::parse("400638133393A");
        assert!(matches!(result, Err(EanError::NonNumeric)));
    }

    #[test]
    fn test_hash_deterministic() {
        let ean = EanCode::parse("4006381333931").unwrap();
        let h1 = ean.to_hash_bytes();
        let h2 = ean.to_hash_bytes();
        assert_eq!(h1, h2);
        assert_eq!(h1.len(), 32);
    }
}
