import 'package:flutter/foundation.dart';
import 'pin_service.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static bool _isUnlocked = false;

  static bool get isAppUnlocked => _isUnlocked;

  static set isAppUnlocked(bool value) {
    if (_isUnlocked != value) {
      _isUnlocked = value;
      _instance.notifyListeners();
    }
  }

  static Future<bool> shouldShowLockScreen() async {
    if (_isUnlocked) return false;
    final hasPinSet = await PinService.hasPin();
    return hasPinSet;
  }
}