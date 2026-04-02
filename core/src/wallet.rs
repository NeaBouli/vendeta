//! Vendetta HD Wallet
//! One seed phrase for everything:
//! - ETH wallet (BIP44 m/44'/60'/0'/0/0)
//! - Vendetta user_hash (SHA256 + device_salt)

use bip39::{Language, Mnemonic};
use bip32::{DerivationPath, XPrv};
use k256::ecdsa::SigningKey;
use tiny_keccak::{Hasher, Keccak};
use rand::RngCore;
use std::str::FromStr;

use crate::hash::sha256_bytes;

const ETH_DERIVATION_PATH: &str = "m/44'/60'/0'/0/0";

#[derive(Debug, Clone)]
pub struct WalletKeys {
    pub mnemonic: String,
    pub eth_address: String,
    pub private_key_bytes: [u8; 32],
    pub user_hash: [u8; 32],
}

#[derive(Debug, thiserror::Error)]
pub enum WalletError {
    #[error("BIP39 error: {0}")]
    Bip39(String),
    #[error("BIP32 derivation error: {0}")]
    Bip32(String),
    #[error("Invalid word count")]
    InvalidWordCount,
}

/// Generate a new wallet from fresh entropy
pub fn generate_wallet(
    device_salt: &[u8; 32],
) -> Result<WalletKeys, WalletError> {
    let mut entropy = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut entropy);
    wallet_from_entropy(&entropy, device_salt)
}

/// Restore wallet from existing mnemonic
pub fn restore_wallet(
    mnemonic_str: &str,
    device_salt: &[u8; 32],
) -> Result<WalletKeys, WalletError> {
    let mnemonic = Mnemonic::parse_in(Language::English, mnemonic_str)
        .map_err(|e| WalletError::Bip39(e.to_string()))?;
    let entropy = mnemonic.to_entropy();
    let entropy_bytes: [u8; 16] = entropy
        .try_into()
        .map_err(|_| WalletError::InvalidWordCount)?;
    wallet_from_entropy(&entropy_bytes, device_salt)
}

fn wallet_from_entropy(
    entropy: &[u8; 16],
    device_salt: &[u8; 32],
) -> Result<WalletKeys, WalletError> {
    // BIP39: entropy -> mnemonic -> seed
    let mnemonic = Mnemonic::from_entropy(entropy)
        .map_err(|e| WalletError::Bip39(e.to_string()))?;
    let seed = mnemonic.to_seed("");

    // BIP32: seed -> master -> BIP44 child
    let master = XPrv::new(seed)
        .map_err(|e| WalletError::Bip32(e.to_string()))?;
    let path = DerivationPath::from_str(ETH_DERIVATION_PATH)
        .map_err(|e| WalletError::Bip32(e.to_string()))?;
    let child = path.into_iter().try_fold(master, |key, child_num| {
        key.derive_child(child_num)
    }).map_err(|e| WalletError::Bip32(e.to_string()))?;

    // ETH private key + address
    let private_key_bytes: [u8; 32] = child.private_key().to_bytes().into();
    let eth_address = eth_address_from_key(&private_key_bytes);

    // Vendetta user_hash = SHA256(entropy || device_salt)
    let mut hash_input = Vec::with_capacity(48);
    hash_input.extend_from_slice(entropy);
    hash_input.extend_from_slice(device_salt);
    let user_hash = sha256_bytes(&hash_input);

    Ok(WalletKeys {
        mnemonic: mnemonic.to_string(),
        eth_address,
        private_key_bytes,
        user_hash,
    })
}

/// Derive ETH address from private key
pub fn eth_address_from_key(private_key_bytes: &[u8; 32]) -> String {
    let signing_key = SigningKey::from_bytes(private_key_bytes.into())
        .expect("Valid private key");
    let verifying_key = signing_key.verifying_key();
    let public_key = verifying_key.to_encoded_point(false);
    let pub_bytes = &public_key.as_bytes()[1..]; // skip 0x04 prefix

    let mut hasher = Keccak::v256();
    let mut output = [0u8; 32];
    hasher.update(pub_bytes);
    hasher.finalize(&mut output);

    let addr_bytes = &output[12..];
    format!("0x{}", hex::encode(addr_bytes))
}

/// Validate mnemonic phrase
pub fn validate_mnemonic(mnemonic_str: &str) -> bool {
    Mnemonic::parse_in(Language::English, mnemonic_str).is_ok()
}

/// Count mnemonic words
pub fn mnemonic_word_count(mnemonic_str: &str) -> usize {
    mnemonic_str.split_whitespace().count()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_salt() -> [u8; 32] { [0u8; 32] }

    #[test]
    fn test_generate_creates_valid_mnemonic() {
        let w = generate_wallet(&test_salt()).unwrap();
        assert!(validate_mnemonic(&w.mnemonic));
        assert_eq!(mnemonic_word_count(&w.mnemonic), 12);
    }

    #[test]
    fn test_eth_address_format() {
        let w = generate_wallet(&test_salt()).unwrap();
        assert!(w.eth_address.starts_with("0x"));
        assert_eq!(w.eth_address.len(), 42);
    }

    #[test]
    fn test_user_hash_32_bytes() {
        let w = generate_wallet(&test_salt()).unwrap();
        assert_eq!(w.user_hash.len(), 32);
    }

    #[test]
    fn test_restore_from_mnemonic() {
        let w1 = generate_wallet(&test_salt()).unwrap();
        let w2 = restore_wallet(&w1.mnemonic, &test_salt()).unwrap();
        assert_eq!(w1.eth_address, w2.eth_address);
        assert_eq!(w1.user_hash, w2.user_hash);
    }

    #[test]
    fn test_different_salts_different_user_hash() {
        let w1 = generate_wallet(&[0u8; 32]).unwrap();
        let mut salt2 = [0u8; 32];
        salt2[0] = 1;
        let w2 = restore_wallet(&w1.mnemonic, &salt2).unwrap();
        assert_eq!(w1.eth_address, w2.eth_address); // same BIP44
        assert_ne!(w1.user_hash, w2.user_hash);     // different salt
    }

    #[test]
    fn test_invalid_mnemonic_rejected() {
        let result = restore_wallet("invalid words here", &test_salt());
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_mnemonic_valid() {
        let w = generate_wallet(&test_salt()).unwrap();
        assert!(validate_mnemonic(&w.mnemonic));
    }

    #[test]
    fn test_validate_mnemonic_invalid() {
        assert!(!validate_mnemonic("these words are not valid bip39"));
    }

    #[test]
    fn test_private_key_not_zero() {
        let w = generate_wallet(&test_salt()).unwrap();
        assert_ne!(w.private_key_bytes, [0u8; 32]);
    }

    #[test]
    fn test_deterministic_from_known_mnemonic() {
        let known = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let w1 = restore_wallet(known, &test_salt()).unwrap();
        let w2 = restore_wallet(known, &test_salt()).unwrap();
        assert_eq!(w1.eth_address, w2.eth_address);
        assert!(w1.eth_address.starts_with("0x"));
        assert_eq!(w1.eth_address.len(), 42);
    }
}
