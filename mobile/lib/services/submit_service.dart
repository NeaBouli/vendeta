import 'package:flutter/foundation.dart';
import '../bridge/vendetta_bridge.dart';
import 'location_service.dart';

enum SubmitStatus { idle, validating, hashing, submitting, confirmed, error }

class SubmitResult {
  final bool success;
  final String? txHash;
  final int? creditsEarned;
  final bool? isFirstMover;
  final String? error;

  const SubmitResult({required this.success, this.txHash, this.creditsEarned, this.isFirstMover, this.error});
}

class SubmitService {
  static SubmitService? _i;
  static SubmitService get instance => _i ??= SubmitService._();
  SubmitService._();

  final _bridge = VendettaBridge.instance;

  Future<SubmitResult> submitPrice({
    required String ean,
    required int priceCents,
    required String currency,
    required String userHash,
    void Function(SubmitStatus)? onStatus,
  }) async {
    try {
      onStatus?.call(SubmitStatus.validating);
      final validEan = await _bridge.validateEan(ean);
      if (!validEan && ean != 'MANUAL') {
        return const SubmitResult(success: false, error: 'Ungültiger Barcode');
      }

      final pos = await LocationService.instance.currentPosition();
      if (pos == null) {
        return const SubmitResult(success: false, error: 'GPS nicht verfügbar');
      }
      if (!LocationService.instance.isAccuracyOk(pos.accuracy)) {
        return const SubmitResult(success: false, error: 'GPS-Signal zu schwach');
      }

      onStatus?.call(SubmitStatus.hashing);
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final hash = await _bridge.generateHash(
        ean: ean, priceCents: priceCents,
        latitude: pos.latitude, longitude: pos.longitude,
        timestamp: ts, userId: userHash,
      );

      final geohash = await _bridge.encodeGeohash(pos.latitude, pos.longitude);
      final lat6 = _bridge.latToInt32(pos.latitude);
      final lng6 = _bridge.lngToInt32(pos.longitude);

      debugPrint('Submit: hash=$hash ean=$ean price=$priceCents lat6=$lat6 lng6=$lng6 geo=$geohash');

      onStatus?.call(SubmitStatus.submitting);

      // Phase 1: optimistic simulation
      await Future.delayed(const Duration(milliseconds: 800));

      final isFirst = hash.endsWith('a') || hash.endsWith('1') || hash.endsWith('e');
      final credits = (100 * 0.5 * (isFirst ? 2.0 : 1.0)).round();

      onStatus?.call(SubmitStatus.confirmed);
      return SubmitResult(
        success: true,
        txHash: '0x${hash.substring(0, 16)}...',
        creditsEarned: credits,
        isFirstMover: isFirst,
      );
    } catch (e) {
      onStatus?.call(SubmitStatus.error);
      return SubmitResult(success: false, error: e.toString());
    }
  }
}
