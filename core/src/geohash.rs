const BASE32: &[u8] = b"0123456789bcdefghjkmnpqrstuvwxyz";

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum GeohashPrecision {
    P3 = 3,
    P4 = 4,
    P5 = 5,
}

/// Encode GPS coordinates as geohash string
/// Precision 5 = ~1.2km² (Vendetta standard)
pub fn encode_geohash(
    lat: f64,
    lng: f64,
    precision: GeohashPrecision,
) -> String {
    let len = precision as usize;
    let mut result = String::with_capacity(len);
    let (mut min_lat, mut max_lat) = (-90.0_f64, 90.0_f64);
    let (mut min_lng, mut max_lng) = (-180.0_f64, 180.0_f64);
    let mut is_lng = true;
    let mut bits = 0u8;
    let mut bitmask = 16u8;
    let mut ch = 0u8;

    while result.len() < len {
        if is_lng {
            let mid = (min_lng + max_lng) / 2.0;
            if lng >= mid {
                ch |= bitmask;
                min_lng = mid;
            } else {
                max_lng = mid;
            }
        } else {
            let mid = (min_lat + max_lat) / 2.0;
            if lat >= mid {
                ch |= bitmask;
                min_lat = mid;
            } else {
                max_lat = mid;
            }
        }
        is_lng = !is_lng;
        bitmask >>= 1;
        bits += 1;

        if bits == 5 {
            result.push(BASE32[ch as usize] as char);
            ch = 0;
            bitmask = 16;
            bits = 0;
        }
    }
    result
}

/// Get all 8 neighboring geohash cells + center (9 total)
/// Used for Multi-Cell Query to avoid boundary effects
pub fn geohash_neighbors(center: &str) -> Vec<String> {
    let precision = center.len();
    // Geohash cell dimensions depend on precision and bit layout
    // Precision 5 = 25 bits total: 13 lng bits, 12 lat bits
    // lat_bits and lng_bits alternate, starting with lng
    let total_bits = precision * 5;
    let lng_bits = total_bits.div_ceil(2);
    let lat_bits = total_bits / 2;
    let lat_step = 180.0 / (1u64 << lat_bits) as f64;
    let lng_step = 360.0 / (1u64 << lng_bits) as f64;

    let mut neighbors = vec![center.to_string()];

    if let Some((lat, lng)) = decode_geohash_center(center) {
        let offsets = [
            (lat_step, 0.0),        // N
            (lat_step, lng_step),   // NE
            (0.0, lng_step),        // E
            (-lat_step, lng_step),  // SE
            (-lat_step, 0.0),       // S
            (-lat_step, -lng_step), // SW
            (0.0, -lng_step),       // W
            (lat_step, -lng_step),  // NW
        ];
        let p = match precision {
            3 => GeohashPrecision::P3,
            4 => GeohashPrecision::P4,
            _ => GeohashPrecision::P5,
        };
        for (dlat, dlng) in &offsets {
            let nlat = (lat + dlat).clamp(-90.0, 90.0);
            let nlng = ((lng + dlng + 540.0) % 360.0) - 180.0;
            let gh = encode_geohash(nlat, nlng, p);
            if gh != center {
                neighbors.push(gh);
            }
        }
        neighbors.sort();
        neighbors.dedup();
    }
    neighbors
}

/// Decode geohash to approximate center coordinates
pub fn decode_geohash_center(hash: &str) -> Option<(f64, f64)> {
    let (mut min_lat, mut max_lat) = (-90.0_f64, 90.0_f64);
    let (mut min_lng, mut max_lng) = (-180.0_f64, 180.0_f64);
    let mut is_lng = true;

    for ch in hash.chars() {
        let idx = BASE32.iter().position(|&b| b == ch as u8)?;
        for bit in (0..5).rev() {
            if is_lng {
                let mid = (min_lng + max_lng) / 2.0;
                if (idx >> bit) & 1 == 1 {
                    min_lng = mid;
                } else {
                    max_lng = mid;
                }
            } else {
                let mid = (min_lat + max_lat) / 2.0;
                if (idx >> bit) & 1 == 1 {
                    min_lat = mid;
                } else {
                    max_lat = mid;
                }
            }
            is_lng = !is_lng;
        }
    }
    Some(((min_lat + max_lat) / 2.0, (min_lng + max_lng) / 2.0))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_munich_geohash5() {
        let gh = encode_geohash(48.137154, 11.576124, GeohashPrecision::P5);
        assert_eq!(gh.len(), 5);
        assert!(
            gh.starts_with("u28"),
            "Munich should start with u28, got: {}",
            gh
        );
    }

    #[test]
    fn test_geohash_neighbors_returns_multiple() {
        let neighbors = geohash_neighbors("u281z");
        assert!(
            neighbors.len() >= 5 && neighbors.len() <= 9,
            "Should return 5-9 unique cells, got: {} {:?}",
            neighbors.len(),
            neighbors
        );
        assert!(
            neighbors.contains(&"u281z".to_string()),
            "Must contain center cell"
        );
    }

    #[test]
    fn test_decode_roundtrip() {
        let lat = 48.137154_f64;
        let lng = 11.576124_f64;
        let gh = encode_geohash(lat, lng, GeohashPrecision::P5);
        let (dlat, dlng) = decode_geohash_center(&gh).unwrap();
        assert!((dlat - lat).abs() < 0.01);
        assert!((dlng - lng).abs() < 0.01);
    }

    #[test]
    fn test_all_precisions() {
        let lat = 48.137154;
        let lng = 11.576124;
        assert_eq!(encode_geohash(lat, lng, GeohashPrecision::P3).len(), 3);
        assert_eq!(encode_geohash(lat, lng, GeohashPrecision::P4).len(), 4);
        assert_eq!(encode_geohash(lat, lng, GeohashPrecision::P5).len(), 5);
    }
}
