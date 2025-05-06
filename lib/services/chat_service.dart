import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> criarSalaSeNaoExistir(String roomName) async {
    final chatRef = _firestore.collection('chats').doc(roomName);
    final salaRef = _firestore.collection('salas').doc(roomName);

    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({'createdAt': FieldValue.serverTimestamp()});
    }

    final salaDoc = await salaRef.get();
    if (!salaDoc.exists) {
      await salaRef.set({
        'nome': roomName, // Aqui salva o nome correto da sala
        'usuarios': [],
        'limite': 20,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> adicionarUsuarioOnline(
    String roomName,
    String nomeUsuario,
    String photoUrl,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      await _firestore
          .collection('chats')
          .doc(roomName)
          .collection('usersOnline')
          .doc(uid)
          .set({
            'nome': user.displayName ?? nomeUsuario,
            'photoUrl': photoUrl,
            'lastSeen': FieldValue.serverTimestamp(),
          });
      // Adiciona no array "usuarios" da sala
      await _firestore.collection('salas').doc(roomName).update({
        'usuarios': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> removerUsuarioOnline(String roomName) async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      await _firestore
          .collection('chats')
          .doc(roomName)
          .collection('usersOnline')
          .doc(uid)
          .delete();
      // Remove do array "usuarios" na sala
      await _firestore.collection('salas').doc(roomName).update({
        'usuarios': FieldValue.arrayRemove([uid]),
      });
    }
  }

  Future<String?> buscarNomeSala(String roomName) async {
    final doc = await _firestore.collection('salas').doc(roomName).get();
    if (doc.exists) {
      return doc.data()?['nome'] ?? roomName;
    }
    return roomName;
  }

  Future<void> enviarMensagem(
    String roomName,
    String message,
    String nomeUsuario,
    String photoUrl,
  ) async {
    final user = _auth.currentUser;
    if (user != null && message.trim().isNotEmpty) {
      await _firestore.collection('chats/$roomName/messages').add({
        'text': message.trim(),
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'userName': user.displayName ?? nomeUsuario,
        'photoUrl': photoUrl,
      });
    }
  }
}
