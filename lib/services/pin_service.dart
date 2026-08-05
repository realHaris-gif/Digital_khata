import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const String _pinHashKey = 'app_secure_pin_hash';
  static const String _saltKey = 'app_secure_pin_salt';

  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin-$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> savePin(String pin) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  static Future<bool> verifyPin(String inputPin) async {
    final salt = await _storage.read(key: _saltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;
    final inputHash = _hashPin(inputPin, salt);
    return inputHash == storedHash;
  }

  static Future<void> removePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _saltKey);
  }
}