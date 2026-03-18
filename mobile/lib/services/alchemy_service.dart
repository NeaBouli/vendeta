import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Alchemy API Service for ETH + IFR balances
/// Free tier: 300M compute units/month
/// IFR Token: 0x77e99917Eca8539c62F509ED1193ac36580A6e7B
/// IFR Decimals: 9 (NOT 18!)
class AlchemyService {
  static AlchemyService? _i;
  static AlchemyService get instance => _i ??= AlchemyService._();
  AlchemyService._();

  // TODO: Replace with real Alchemy key from .env
  // Get free key at alchemy.com
  static const _ethMainnet = 'https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY';
  static const _ifrToken = '0x77e99917Eca8539c62F509ED1193ac36580A6e7B';
  static const _lockContract = '0x769928aBDfc949D0718d8766a1C2d7dBb63954Eb';

  Future<double> getEthBalance(String address) async {
    try {
      final resp = await _rpc('eth_getBalance', [address, 'latest']);
      final hex = resp as String?;
      if (hex == null) return 0.0;
      final wei = BigInt.parse(hex.replaceFirst('0x', ''), radix: 16);
      return wei.toDouble() / 1e18;
    } catch (e) {
      debugPrint('ETH balance error: $e');
      return 0.0;
    }
  }

  Future<double> getIfrBalance(String address) async {
    try {
      final resp = await _rpc('alchemy_getTokenBalances', [address, [_ifrToken]]);
      if (resp == null) return 0.0;
      final balances = (resp as Map)['tokenBalances'] as List?;
      if (balances == null || balances.isEmpty) return 0.0;
      final hex = balances[0]['tokenBalance'] as String?;
      if (hex == null || hex == '0x0' || hex == '0x') return 0.0;
      final raw = BigInt.parse(hex.replaceFirst('0x', ''), radix: 16);
      return raw.toDouble() / 1e9; // IFR = 9 decimals
    } catch (e) {
      debugPrint('IFR balance error: $e');
      return 0.0;
    }
  }

  Future<({double eth, double ifr})> getAllBalances(String address) async {
    final results = await Future.wait([getEthBalance(address), getIfrBalance(address)]);
    return (eth: results[0], ifr: results[1]);
  }

  /// Check IFR Lock status via eth_call to IFRLock contract
  Future<bool> isIfrLocked(String walletAddress, double minIfrAmount) async {
    try {
      final minRaw = BigInt.from((minIfrAmount * 1e9).round());
      final minHex = minRaw.toRadixString(16).padLeft(64, '0');
      final addrHex = walletAddress.replaceFirst('0x', '').padLeft(64, '0');
      // isLocked(address,uint256) selector: 0x2b0a7899
      final callData = '0x2b0a7899$addrHex$minHex';

      final resp = await _rpc('eth_call', [{'to': _lockContract, 'data': callData}, 'latest']);
      if (resp == null) return false;
      return (resp as String).endsWith('1');
    } catch (e) {
      debugPrint('isLocked error: $e');
      return false;
    }
  }

  Future<double> getLockedIfrBalance(String walletAddress) async {
    try {
      final addrHex = walletAddress.replaceFirst('0x', '').padLeft(64, '0');
      // lockedBalance(address) selector: 0x1a6952f7
      final callData = '0x1a6952f7$addrHex';

      final resp = await _rpc('eth_call', [{'to': _lockContract, 'data': callData}, 'latest']);
      if (resp == null || resp == '0x') return 0.0;
      final raw = BigInt.parse((resp as String).replaceFirst('0x', ''), radix: 16);
      return raw.toDouble() / 1e9;
    } catch (e) {
      debugPrint('lockedBalance error: $e');
      return 0.0;
    }
  }

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final resp = await http
        .post(
          Uri.parse(_ethMainnet),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}),
        )
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(resp.body);
    return data['result'];
  }
}
