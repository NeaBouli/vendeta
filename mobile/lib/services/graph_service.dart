import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/price_pin.dart';
import '../models/user_stats.dart';

class GraphService {
  static GraphService? _i;
  static GraphService get instance => _i ??= GraphService._();
  GraphService._();

  static const _endpoint = 'https://api.studio.thegraph.com/query/1744627/vendetta-price-network/v0.1.0';

  Future<List<PricePin>> nearbyPrices({
    required String geohash,
    required String currency,
    int limit = 100,
  }) async {
    const query = r'''
query NearbyPrices($cells: [String!]!, $currency: String!, $limit: Int!) {
  submissions(
    where: { geohash5_in: $cells, currency: $currency, status_in: [1, 2] }
    orderBy: timestamp
    orderDirection: desc
    first: $limit
  ) {
    id price_cents currency lat6 lng6 geohash5
    is_first_mover status timestamp
    user_hash { trust_score tier_level }
  }
}''';

    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'variables': {'cells': [geohash], 'currency': currency, 'limit': limit},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        debugPrint('Graph error: ${resp.statusCode}');
        return _mockPins();
      }

      final data = jsonDecode(resp.body);
      final list = data['data']?['submissions'] as List? ?? [];
      return list.map((j) => PricePin.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Graph exception: $e');
      return _mockPins();
    }
  }

  Future<UserStats> getUserStats(String userHash) async {
    const query = r'''
query UserStatus($user: Bytes!) {
  user(id: $user) {
    trust_score tier_level current_credits total_claimed total_submissions
  }
}''';

    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'variables': {'user': userHash},
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body);
      final user = data['data']?['user'];
      if (user == null) return UserStats.empty(userHash);
      return UserStats.fromJson(user as Map<String, dynamic>);
    } catch (e) {
      return UserStats.empty(userHash);
    }
  }

  List<PricePin> _mockPins() => const [
        PricePin(
            id: '0xmock1', eanHash: '0xabc', priceCents: 79, currency: 'EUR',
            lat6: 48137154, lng6: 11576124, geohash5: 'u281z',
            isFirstMover: true, status: 2, timestamp: 1742000000, trustScore: 820),
        PricePin(
            id: '0xmock2', eanHash: '0xdef', priceCents: 149, currency: 'EUR',
            lat6: 48139000, lng6: 11580000, geohash5: 'u281z',
            isFirstMover: false, status: 1, timestamp: 1742001000, trustScore: 650),
        PricePin(
            id: '0xmock3', eanHash: '0xghi', priceCents: 299, currency: 'EUR',
            lat6: 48135000, lng6: 11572000, geohash5: 'u281z',
            isFirstMover: true, status: 2, timestamp: 1742002000, trustScore: 900),
      ];
}
