import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';
import 'package:pheli_fla_app/screens/home_screen.dart';

class RoomSelectionScreen extends StatelessWidget {
  const RoomSelectionScreen({super.key});

  final List<String> salaIds = const [
    'sala_geral',
    'sala_bastidores',
    'sala_jogo',
    'sala_resenha',
    'sala_mulheres',
  ];

  void _enterChatRoom(
    BuildContext context,
    String roomId,
    String nomeUsuario,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final photoUrl = user?.photoURL ?? '';

    final salaRef = FirebaseFirestore.instance.collection('salas').doc(roomId);
    final doc = await salaRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> usuarios = data['usuarios'] ?? [];
    final int limite = data['limite'] ?? 20;

    if (usuarios.contains(uid)) {
      // usuário já na sala, continuar
    } else if (usuarios.length >= limite) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sala cheia! Tente outra.')));
      return;
    } else {
      // adiciona usuário à lista
      usuarios.add(uid);
      await salaRef.update({
        'usuarios': FieldValue.arrayUnion([uid]),
      });
    }
    final nomeSala = data['nome'] ?? roomId;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              roomName: roomId,
              nomeUsuario: nomeUsuario,
              photoUrl: photoUrl,
            ),
      ),
    );
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
        builder:
            (_) => HomeScreen(
              nomeUsuario: nomeUsuario,
              isDarkMode: false,
              onThemeChanged: (_) {},
              isPlusUser: true,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha uma Sala'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _goToHome(context),
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
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('salas')
                  .where('excluida', isNotEqualTo: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(30),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final nome = data['nome'] ?? 'Sala';
                final usuarios = List.from(data['usuarios'] ?? []);
                final limite = data['limite'] ?? 20;
                final salaId = doc.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed:
                        usuarios.length >= limite
                            ? null
                            : () =>
                                _enterChatRoom(context, salaId, nomeUsuario),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '$nome (${usuarios.length}/$limite)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TextButton(
          onPressed: () => _cancelAndGoToLogin(context),
          child: const Text(
            'Sair do App',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 228, 3, 3),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nomeSalaController = TextEditingController();
          final limiteController = TextEditingController(text: '20');

          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Criar nova sala'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nomeSalaController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da sala',
                        ),
                      ),
                      TextField(
                        controller: limiteController,
                        decoration: const InputDecoration(
                          labelText: 'Limite de usuários',
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
                      child: const Text('Criar'),
                      onPressed: () async {
                        final nome = nomeSalaController.text.trim();
                        int limite =
                            int.tryParse(limiteController.text.trim()) ?? 20;
                        if (limite < 2) limite = 2;
                        if (limite > 100) limite = 100;
                        if (nome.isEmpty) return;

                        await FirebaseFirestore.instance
                            .collection('salas')
                            .add({
                              'nome': nome,
                              'limite': limite,
                              'usuarios': [],
                              'excluida': false,
                            });

                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.red[800],
      ),
    );
  }
}
