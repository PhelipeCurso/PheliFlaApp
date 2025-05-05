import 'package:pheli_fla_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomSelectionScreen extends StatelessWidget {
  const RoomSelectionScreen({super.key});

  void _enterChatRoom(
    BuildContext context,
    String roomName,
    String nomeUsuario,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL ?? '';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              roomName: roomName,
              nomeUsuario: nomeUsuario,
              photoUrl: photoUrl,
            ),
      ),
    );
  }

  void _cancelAndGoToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Pegando o nomeUsuario passado como argumento
    final nomeUsuario = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha uma Sala'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              final nomeUsuario = user?.displayName ?? 'Usuário';
              final photoUrl = user?.photoURL ?? '';
              //Navigator.pushNamedAndRemoveUntil(
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => HomeScreen(
                        nomeUsuario: nomeUsuario,
                        //photoUrl: photoUrl,
                        isDarkMode: false, // ou pegue do app
                        onThemeChanged: (_) {},
                      ),
                ),
                //'/home_screen',
                //(route) => false,
              );
            },
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoomButton(
                  context,
                  'Sala Masculina 🔴',
                  'homens',
                  nomeUsuario,
                  Colors.red[800]!,
                ),
                const SizedBox(height: 20),
                _buildRoomButton(
                  context,
                  'Sala Feminina ⚫',
                  'mulheres',
                  nomeUsuario,
                  Colors.pink,
                ),
                const SizedBox(height: 20),
                _buildRoomButton(
                  context,
                  'Sala Mista 🔴⚫',
                  'todos',
                  nomeUsuario,
                  Colors.black87,
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () => _cancelAndGoToLogin(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomButton(
    BuildContext context,
    String label,
    String room,
    String nomeUsuario,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () => _enterChatRoom(context, room, nomeUsuario),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
