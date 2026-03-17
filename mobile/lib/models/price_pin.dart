class PricePin {
  final String id;
  final String eanHash;
  final int priceCents;
  final String currency;
  final int lat6;
  final int lng6;
  final String geohash5;
  final bool isFirstMover;
  final int status;
  final int timestamp;
  final int trustScore;

  const PricePin({
    required this.id,
    required this.eanHash,
    required this.priceCents,
    required this.currency,
    required this.lat6,
    required this.lng6,
    required this.geohash5,
    required this.isFirstMover,
    required this.status,
    required this.timestamp,
    required this.trustScore,
  });

  factory PricePin.fromJson(Map<String, dynamic> j) => PricePin(
        id: j['id'] ?? '',
        eanHash: j['ean_hash'] ?? '',
        priceCents: int.tryParse(j['price_cents']?.toString() ?? '0') ?? 0,
        currency: j['currency'] ?? 'EUR',
        lat6: j['lat6'] ?? 0,
        lng6: j['lng6'] ?? 0,
        geohash5: j['geohash5'] ?? '',
        isFirstMover: j['is_first_mover'] ?? false,
        status: j['status'] ?? 0,
        timestamp: int.tryParse(j['timestamp']?.toString() ?? '0') ?? 0,
        trustScore: j['user_hash']?['trust_score'] ?? 500,
      );

  double get latitude => lat6 / 1000000.0;
  double get longitude => lng6 / 1000000.0;

  String get priceDisplay {
    final euros = priceCents ~/ 100;
    final cents = priceCents % 100;
    return '$euros.${cents.toString().padLeft(2, '0')} $currency';
  }
}
