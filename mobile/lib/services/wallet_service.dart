import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../bridge/vendetta_bridge.dart';
import 'alchemy_service.dart';

enum WalletMode { notCreated, selfCustody, standard }

class WalletBalance {
  final double ifr;
  final double eth;
  final String address;
  const WalletBalance({required this.ifr, required this.eth, required this.address});
  static const empty = WalletBalance(ifr: 0, eth: 0, address: '');
}

class WalletService {
  static WalletService? _i;
  static WalletService get instance => _i ??= WalletService._();
  WalletService._();

  static const _storage = FlutterSecureStorage(
      aOptions: AndroidOptions());

  WalletMode _mode = WalletMode.notCreated;
  String? _address;
  String? _userHash;

  WalletMode get mode => _mode;
  String? get address => _address;
  String? get userHash => _userHash;
  bool get hasWallet => _mode != WalletMode.notCreated;

  Future<void> initialize() async {
    final mode = await _storage.read(key: 'wallet_mode');
    _address = await _storage.read(key: 'eth_address');
    _userHash = await _storage.read(key: 'user_hash');
    _mode = mode == 'self_custody' && _address != null
        ? WalletMode.selfCustody
        : WalletMode.notCreated;
    debugPrint('Wallet: $_mode $_address');
  }

  Future<String> createWallet() async {
    final salt = _deviceSalt();
    final result = await VendettaBridge.instance.generateWallet(deviceSalt: salt);
    await _storage.write(key: 'eth_address', value: result['ethAddress']);
    await _storage.write(key: 'user_hash', value: result['userHash']);
    await _storage.write(key: 'wallet_mode', value: 'self_custody');
    await _storage.write(key: 'mnemonic_enc', value: result['mnemonic']);
    _address = result['ethAddress'];
    _userHash = result['userHash'];
    _mode = WalletMode.selfCustody;
    return result['ethAddress']!;
  }

  Future<bool> restoreFromMnemonic(String mnemonic) async {
    try {
      final salt = _deviceSalt();
      final result = await VendettaBridge.instance.restoreWallet(mnemonic: mnemonic, deviceSalt: salt);
      await _storage.write(key: 'eth_address', value: result['ethAddress']);
      await _storage.write(key: 'user_hash', value: result['userHash']);
      await _storage.write(key: 'wallet_mode', value: 'self_custody');
      await _storage.write(key: 'mnemonic_enc', value: mnemonic);
      _address = result['ethAddress'];
      _userHash = result['userHash'];
      _mode = WalletMode.selfCustody;
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Future<WalletBalance> getBalance() async {
    if (_address == null) return WalletBalance.empty;
    try {
      final balances = await AlchemyService.instance.getAllBalances(_address!);
      return WalletBalance(ifr: balances.ifr, eth: balances.eth, address: _address!);
    } catch (e) {
      debugPrint('Balance error: $e');
      return WalletBalance(ifr: 0, eth: 0, address: _address!);
    }
  }

  Future<String?> getMnemonicForBackup() async => _storage.read(key: 'mnemonic_enc');

  String shortAddress(String addr) {
    if (addr.length < 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  List<int> _deviceSalt() => List.generate(32, (i) => i);
}
