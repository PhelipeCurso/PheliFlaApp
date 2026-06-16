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

      // Aproveita a entrada para limpar usuários inativos da sala
      limparUsuariosInativos(roomName);
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

  // --- ATUALIZAR STATUS DE ATIVIDADE ---
  Future<void> atualizarAtividade(String roomName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('chats')
          .doc(roomName)
          .collection('usersOnline')
          .doc(user.uid)
          .update({
            'lastSeen': FieldValue.serverTimestamp(),
          });
    }
  }

  // --- REMOVER USUÁRIOS INATIVOS (MAIS DE 5 MINUTOS) ---
  Future<void> limparUsuariosInativos(String roomName) async {
    try {
      // Define o ponto de corte (Tempo atual menos 5 minutos)
      final limiteInatividade = DateTime.now().subtract(const Duration(minutes: 5));
      
      // Busca usuários cujo 'lastSeen' seja anterior ao limite de 5 minutos
      final snapshot = await _firestore
          .collection('chats')
          .doc(roomName)
          .collection('usersOnline')
          .where('lastSeen', isLessThan: limiteInatividade)
          .get();

      if (snapshot.docs.isEmpty) return;

      final WriteBatch batch = _firestore.batch();
      List<String> uidsRemover = [];

      for (var doc in snapshot.docs) {
        uidsRemover.add(doc.id);
        // Adiciona a deleção do documento de usersOnline ao lote
        batch.delete(doc.reference);
      }

      // Executa a remoção do lote no Firestore
      await batch.commit();

      // Atualiza o array da coleção 'salas' removendo todos esses IDs inativos de uma vez
      if (uidsRemover.isNotEmpty) {
        await _firestore.collection('salas').doc(roomName).update({
          'usuarios': FieldValue.arrayRemove(uidsRemover),
        });
        print("${uidsRemover.length} usuários inativos foram removidos da sala $roomName.");
      }
    } catch (e) {
      print("Erro ao limpar usuários inativos: $e");
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

      if (!await audioFile.exists()) {
        print("Erro: Arquivo de áudio não encontrado no caminho local.");
        return;
      }

      final String fileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'audio/m4a',
        customMetadata: {'userId': user.uid},
      );

      final Reference ref = _storage
          .ref()
          .child('chats')
          .child(roomName)
          .child('audios')
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(audioFile, metadata);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        print(
          "Upload progresso: ${(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100}%",
        );
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String audioUrl = await snapshot.ref.getDownloadURL();

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

      // --- ATUALIZA E LIMPA INATIVOS ---
      await atualizarAtividade(roomName);
      limparUsuariosInativos(roomName);

      print("Áudio enviado com sucesso para a sala $roomName!");
    } catch (e) {
      print("Erro no ChatService ao enviar áudio: $e");
      rethrow;
    }
  }

  // --- ENVIO DE MENSAGEM DE TEXTO ---
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

    // --- ATUALIZA E LIMPA INATIVOS ---
    await atualizarAtividade(roomName);
    limparUsuariosInativos(roomName);
  }
}