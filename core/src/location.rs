use serde::{Deserialize, Serialize};
use std::f64::consts::PI;

/// GPS coordinates with int32 conversion for on-chain use
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Coordinates {
    pub lat: f64,
    pub lng: f64,
}

/// Bounding box for radius search
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct BoundingBox {
    pub min_lat: f64,
    pub max_lat: f64,
    pub min_lng: f64,
    pub max_lng: f64,
}

impl Coordinates {
    /// Create new coordinates with validation
    pub fn new(lat: f64, lng: f64) -> Option<Self> {
        if lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0 {
            return None;
        }
        Some(Self { lat, lng })
    }

    /// Convert to int32 for on-chain storage (×1e6)
    /// ALWAYS uses .round() — never truncate!
    pub fn to_lat6(&self) -> i32 {
        (self.lat * 1_000_000.0_f64).round() as i32
    }

    /// Convert to int32 for on-chain storage (×1e6)
    pub fn to_lng6(&self) -> i32 {
        (self.lng * 1_000_000.0_f64).round() as i32
    }

    /// Restore from int32 on-chain values
    pub fn from_int32(lat6: i32, lng6: i32) -> Self {
        Self {
            lat: lat6 as f64 / 1_000_000.0,
            lng: lng6 as f64 / 1_000_000.0,
        }
    }
}

/// Haversine distance between two GPS points in meters
pub fn distance_meters(a: &Coordinates, b: &Coordinates) -> f64 {
    const EARTH_RADIUS_M: f64 = 6_371_000.0;

    let lat1 = a.lat.to_radians();
    let lat2 = b.lat.to_radians();
    let dlat = (b.lat - a.lat).to_radians();
    let dlng = (b.lng - a.lng).to_radians();

    let h = (dlat / 2.0).sin().powi(2)
        + lat1.cos() * lat2.cos() * (dlng / 2.0).sin().powi(2);
    let c = 2.0 * h.sqrt().asin();

    EARTH_RADIUS_M * c
}

/// Calculate bounding box for a given center and radius
pub fn bounding_box(center: &Coordinates, radius_m: f64) -> BoundingBox {
    const EARTH_RADIUS_M: f64 = 6_371_000.0;

    let lat_delta = (radius_m / EARTH_RADIUS_M) * (180.0 / PI);
    let lng_delta = lat_delta / center.lat.to_radians().cos();

    BoundingBox {
        min_lat: center.lat - lat_delta,
        max_lat: center.lat + lat_delta,
        min_lng: center.lng - lng_delta,
        max_lng: center.lng + lng_delta,
    }
}

/// Check if a point is within radius_m of center
pub fn is_within_radius(
    center: &Coordinates,
    point: &Coordinates,
    radius_m: f64,
) -> bool {
    distance_meters(center, point) <= radius_m
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_coordinates_valid() {
        assert!(Coordinates::new(48.137154, 11.576124).is_some());
        assert!(Coordinates::new(0.0, 0.0).is_some());
        assert!(Coordinates::new(-90.0, -180.0).is_some());
    }

    #[test]
    fn test_coordinates_invalid() {
        assert!(Coordinates::new(91.0, 0.0).is_none());
        assert!(Coordinates::new(0.0, 181.0).is_none());
    }

    #[test]
    fn test_int32_roundtrip() {
        let c = Coordinates::new(48.137154, 11.576124).unwrap();
        let lat6 = c.to_lat6();
        let lng6 = c.to_lng6();
        assert_eq!(lat6, 48_137_154);
        assert_eq!(lng6, 11_576_124);

        let restored = Coordinates::from_int32(lat6, lng6);
        assert!((restored.lat - c.lat).abs() < 0.000001);
        assert!((restored.lng - c.lng).abs() < 0.000001);
    }

    #[test]
    fn test_no_float_truncation() {
        // 48.1371545 * 1e6 = 48137154.5 → must round to 48137155
        let c = Coordinates::new(48.1371545, 11.576124).unwrap();
        assert_eq!(c.to_lat6(), 48_137_155); // rounded, not truncated
    }

    #[test]
    fn test_haversine_munich_marienplatz_to_hbf() {
        let marienplatz = Coordinates::new(48.137154, 11.576124).unwrap();
        let hbf = Coordinates::new(48.140232, 11.560080).unwrap();
        let dist = distance_meters(&marienplatz, &hbf);
        // ~1.2km between Marienplatz and Hauptbahnhof
        assert!(dist > 1000.0 && dist < 1500.0,
            "Distance should be ~1.2km, got: {}m", dist);
    }

    #[test]
    fn test_same_point_zero_distance() {
        let p = Coordinates::new(48.137154, 11.576124).unwrap();
        assert!(distance_meters(&p, &p) < 0.001);
    }

    #[test]
    fn test_bounding_box_5km() {
        let center = Coordinates::new(48.137154, 11.576124).unwrap();
        let bb = bounding_box(&center, 5000.0);
        assert!(bb.min_lat < center.lat);
        assert!(bb.max_lat > center.lat);
        assert!(bb.min_lng < center.lng);
        assert!(bb.max_lng > center.lng);
    }

    #[test]
    fn test_within_radius() {
        let center = Coordinates::new(48.137154, 11.576124).unwrap();
        let nearby = Coordinates::new(48.138, 11.577).unwrap();
        let far = Coordinates::new(49.0, 12.0).unwrap();
        assert!(is_within_radius(&center, &nearby, 500.0));
        assert!(!is_within_radius(&center, &far, 500.0));
    }
}
