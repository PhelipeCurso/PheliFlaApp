import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserPlusProvider with ChangeNotifier {
  bool _isPlus = false;
  bool get isPlus => _isPlus;

  Future<void> checkPlusStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _isPlus = doc.data()?['isPlus'] ?? false;
      notifyListeners();
    }
  }

  void setPlus(bool value) {
    _isPlus = value;
    notifyListeners();
  }
}
