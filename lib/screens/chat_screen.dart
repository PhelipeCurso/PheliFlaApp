import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart'; // ajuste conforme o caminho do seu projeto

class ChatScreen extends StatefulWidget {
  final String roomName;
  final String nomeUsuario;
  final String photoUrl;

  const ChatScreen({
    super.key,
    required this.roomName,
    required this.nomeUsuario,
    required this.photoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? nomeDaSala;

  @override
  void initState() {
    super.initState();
    _chatService.criarSalaSeNaoExistir(widget.roomName).then((_) {
      _chatService.adicionarUsuarioOnline(
        widget.roomName,
        widget.nomeUsuario,
        widget.photoUrl,
      );
      _carregarNomeSala();
    });
  }

  void _carregarNomeSala() async {
    final nome = await _chatService.buscarNomeSala(widget.roomName);
    setState(() {
      nomeDaSala = nome;
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _chatService.enviarMensagem(
      widget.roomName,
      text,
      widget.nomeUsuario,
      widget.photoUrl,
    );
    _messageController.clear();
  }

  @override
  void dispose() {
    _chatService.removerUsuarioOnline(widget.roomName);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                nomeDaSala ?? 'Carregando...',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('chats')
                      .doc(widget.roomName)
                      .collection('usersOnline')
                      .snapshots(),
              builder: (context, snapshot) {
                final onlineCount = snapshot.data?.docs.length ?? 0;
                return Text(
                  ' ($onlineCount online)',
                  style: const TextStyle(fontSize: 16),
                );
              },
            ),
          ],
        ),

        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _chatService.removerUsuarioOnline(widget.roomName);
              await _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('chats')
                        .doc(widget.roomName)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (ctx, index) {
                      final msgData =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = msgData['userId'] == currentUser?.uid;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment:
                              isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      msgData['photoUrl'] != null &&
                                              msgData['photoUrl'] != ''
                                          ? NetworkImage(msgData['photoUrl'])
                                          : const AssetImage(
                                                'assets/images/Gaming.png',
                                              )
                                              as ImageProvider,
                                ),
                              ),
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isMe
                                          ? Colors.red[800]
                                          : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msgData['userName'] ?? 'Usuário',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isMe
                                                ? Colors.white70
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msgData['text'],
                                      style: TextStyle(
                                        color:
                                            isMe
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msgData['createdAt'] != null
                                          ? (msgData['createdAt'] as Timestamp)
                                              .toDate()
                                              .toLocal()
                                              .toString()
                                              .substring(11, 16)
                                          : '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            isMe
                                                ? Colors.white60
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      msgData['photoUrl'] != null &&
                                              msgData['photoUrl'] != ''
                                          ? NetworkImage(msgData['photoUrl'])
                                          : const AssetImage(
                                                'assets/images/Gaming.png',
                                              )
                                              as ImageProvider,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.red[900],
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
