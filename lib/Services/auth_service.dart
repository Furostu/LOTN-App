import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  Future<void> init() async {
    // Set default PIN if not set
    final pin = await _storage.read(key: 'admin_pin');
    if (pin == null) {
      await _storage.write(key: 'admin_pin', value: '1234');
    }
  }

  Future<bool> tryPin(String inputPin) async {
    final storedPin = await _storage.read(key: 'admin_pin');
    if (inputPin == storedPin) {
      _isAdmin = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAdmin = false;
    notifyListeners();
  }
}
