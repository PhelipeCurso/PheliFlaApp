// lib/services/canto_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/canto_model.dart';

class CantoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para ouvir os cantos em tempo real
  Stream<List<CantoModel>> getCantos() {
    return _db.collection('cantos_torcida').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => CantoModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}