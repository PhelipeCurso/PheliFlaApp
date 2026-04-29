import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/src/widgets/framework.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- GERENCIAMENTO DE SALAS ---

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
        'nome': roomName,
        'usuarios': [],
        'limite': 20,
        'createdAt': FieldValue.serverTimestamp(),
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

  // --- PRESENÇA DE USUÁRIOS ---

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

      await _firestore.collection('salas').doc(roomName).update({
        'usuarios': FieldValue.arrayRemove([uid]),
      });
    }
  }

  // --- ENVIO DE MENSAGENS DE ÁUDIO ATUALIZADO ---

  Future<void> enviarAudio(
    String roomName,
    String filePath,
    String nomeUsuario,
    String photoUrl,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final File audioFile = File(filePath);

      // Validação básica: verificar se o arquivo realmente existe antes de tentar o upload
      if (!await audioFile.exists()) {
        print("Erro: Arquivo de áudio não encontrado no caminho local.");
        return;
      }

      final String fileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 1. Definir os METADADOS (Isso resolve o erro 403 das suas regras)
      final SettableMetadata metadata = SettableMetadata(
        contentType:
            'audio/m4a', // Especifica que é um áudio para satisfazer a regra .matches('audio/.*')
        customMetadata: {'userId': user.uid},
      );

      // 2. Referência no Storage
      final Reference ref = _storage
          .ref()
          .child('chats')
          .child(roomName)
          .child('audios')
          .child(fileName);

      // 3. Upload com metadados
      final UploadTask uploadTask = ref.putFile(audioFile, metadata);

      // Opcional: Log de progresso para acompanhar no console
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        print(
          "Upload progresso: ${(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100}%",
        );
      });

      final TaskSnapshot snapshot = await uploadTask;

      // 4. Obter URL pública
      final String audioUrl = await snapshot.ref.getDownloadURL();

      // 5. Salvar registro no Firestore
      await _firestore
          .collection('chats')
          .doc(roomName)
          .collection('messages')
          .add({
            'type': 'audio',
            'mediaUrl': audioUrl,
            'text': '🎤 Áudio',
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
            'userName': user.displayName ?? nomeUsuario,
            'photoUrl': photoUrl,
          });

      print("Áudio enviado com sucesso para a sala $roomName!");
    } catch (e) {
      print("Erro no ChatService ao enviar áudio: $e");
      rethrow;
    }
  }

  Future<void> enviarMensagem(String roomName, String text, String nomeUsuario, String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('chats')
        .doc(roomName)
        .collection('messages')
        .add({
          'type': 'text',
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'userName': user.displayName ?? nomeUsuario,
          'photoUrl': photoUrl,
        });
  }
}
