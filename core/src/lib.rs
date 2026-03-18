// Copyright (c) 2026 Vendetta Contributors
// SPDX-License-Identifier: MIT

pub mod hash;
pub mod ean;
pub mod location;
pub mod geohash;
pub mod currency;
pub mod wallet;

pub use hash::{SubmissionHash, SubmissionInput, sha256_bytes};
pub use ean::{EanCode, EanError, BarcodeFormat};
pub use location::{Coordinates, BoundingBox,
                   distance_meters, bounding_box,
                   is_within_radius};
pub use geohash::{encode_geohash, geohash_neighbors,
                  GeohashPrecision};
pub use currency::{CurrencyCode, price_to_cents,
                   cents_to_display};
pub use wallet::{WalletKeys, WalletError,
                 generate_wallet, restore_wallet,
                 validate_mnemonic, mnemonic_word_count,
                 eth_address_from_key};
