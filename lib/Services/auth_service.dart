import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;

  Future<bool> login(String pin) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('pin').get();
      final storedPin = doc.data()?['code'];

      print("🔒 Firestore PIN: $storedPin");
      print("🔑 Entered PIN: $pin");

      if (pin == storedPin) {
        _isAdmin = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("❌ Firestore login error: $e");
    }

    return false;
  }

  void logout() {
    _isAdmin = false;
    notifyListeners();
  }
}
