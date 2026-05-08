import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'chat_screen.dart';
import 'package:pheli_fla_app/screens/home_screen.dart';

class RoomSelectionScreen extends StatelessWidget {
  const RoomSelectionScreen({super.key});

  /// Lógica de entrada na sala com gerenciamento de notificações por tópico
  Future<void> _enterChatRoom(
    BuildContext context,
    String roomId,
    String nomeUsuario,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final photoUrl = user?.photoURL ?? '';

    if (uid == null) return;

    final salaRef = FirebaseFirestore.instance.collection('salas').doc(roomId);
    final doc = await salaRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> usuarios = data['usuarios'] ?? [];
    final int limite = data['limite'] ?? 20;

    // 1. Verifica se o usuário já "interagiu" (está na lista) ou se há vaga
    if (!usuarios.contains(uid)) {
      if (usuarios.length >= limite) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sala cheia! Tente outra.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      } else {
        // Registra a interação do usuário adicionando-o ao Firestore
        await salaRef.update({
          'usuarios': FieldValue.arrayUnion([uid]),
        });
      }
    }

    // 2. MELHORIA DE NOTIFICAÇÃO: Inscrição no tópico
    // Isso garante que o usuário receba notificações mesmo com o app fechado,
    // pois o Firebase gerencia a entrega via sistema operacional.
    try {
      await FirebaseMessaging.instance.subscribeToTopic('chat_$roomId');
      debugPrint("✅ Inscrito nas notificações da sala: $roomId");
    } catch (e) {
      debugPrint("❌ Erro ao inscrever no tópico: $e");
    }

    // 3. Navegação para a tela de Chat
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomName: roomId,
            nomeUsuario: nomeUsuario,
            photoUrl: photoUrl,
          ),
        ),
      );
    }
  }

  void _cancelAndGoToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _goToHome(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nomeUsuario = user?.displayName ?? 'Usuário';
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          nomeUsuario: nomeUsuario,
          isDarkMode: false,
          onThemeChanged: (_) {},
          isPlusUser: true, // Mantendo conforme sua lógica atual
        ),
      ),
    );
  }

  /// Dialog para criação de novas salas
  Future<void> _showCreateRoomDialog(BuildContext context) async {
    final nomeSalaController = TextEditingController();
    final limiteController = TextEditingController(text: '20');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Criar Nova Sala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeSalaController,
              decoration: const InputDecoration(
                labelText: 'Nome da sala',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: limiteController,
              decoration: const InputDecoration(
                labelText: 'Limite de usuários',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_add_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar'),
            onPressed: () async {
              final nome = nomeSalaController.text.trim();
              int limite = int.tryParse(limiteController.text.trim()) ?? 20;
              
              if (limite < 2) limite = 2;
              if (limite > 100) limite = 100;
              if (nome.isEmpty) return;

              await FirebaseFirestore.instance.collection('salas').add({
                'nome': nome,
                'limite': limite,
                'usuarios': [],
                'excluida': false,
              });

              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final nomeUsuario = args is String ? args : 'Usuário';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Ir para a Home',
          onPressed: () => _goToHome(context),
        ),
        title: const Text(
          'Escolha uma Sala',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sair do App',
            onPressed: () => _cancelAndGoToLogin(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/PheliFlafundo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('salas')
                .where('excluida', isNotEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma sala disponível no momento.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  final nome = data['nome'] ?? 'Sala';
                  final usuarios = List.from(data['usuarios'] ?? []);
                  final limite = data['limite'] ?? 20;
                  final salaId = doc.id;
                  
                  final bool salaCheia = usuarios.length >= limite;

                  return Card(
                    elevation: 4,
                    color: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${usuarios.length} de $limite participantes',
                        style: TextStyle(
                          color: salaCheia ? Colors.red : Colors.grey[700],
                          fontWeight: salaCheia ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Icon(
                        salaCheia ? Icons.lock : Icons.login,
                        color: salaCheia ? Colors.red : Colors.green[600],
                      ),
                      onTap: salaCheia
                          ? null
                          : () => _enterChatRoom(context, salaId, nomeUsuario),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRoomDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Sala', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[800],
      ),
    );
  }
}