import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final FocusNode _focusNode = FocusNode();
  String? nomeDaSala;
  String selectedBackground = 'assets/images/fundos/PheliFlafundo.png';

  List<String> backgroundImages = [
    'assets/images/fundos/PheliFlafundo.png',
    'assets/images/fundos/ArrascaetaFundo.png',
    'assets/images/fundos/fundoAdidas.png',
    'assets/images/fundos/fundo2019.png',
    'assets/images/fundos/FundoBH.png',
    'assets/images/fundos/fundoerik.png',
    'assets/images/fundos/Pedro.png',
    'assets/images/fundos/UrubuFundo.png',
  ];

  @override
  void initState() {
    super.initState();
   _loadSavedBackground();

    _chatService.criarSalaSeNaoExistir(widget.roomName).then((_) {
      _chatService.adicionarUsuarioOnline(
        widget.roomName,
        widget.nomeUsuario,
        widget.photoUrl,
      );
      _carregarNomeSala();
    });
  }

  void _loadSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg = prefs.getString('chatBackground');
    if (savedBg != null && backgroundImages.contains(savedBg)) {
      setState(() {
        selectedBackground = savedBg;
      });
    }
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

  void _selecionarFundo() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: backgroundImages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (_, index) {
              return GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(
                    'chatBackground',
                    backgroundImages[index],
                  );
                  setState(() {
                    selectedBackground = backgroundImages[index];
                  });
                  Navigator.pop(context);
                },
                child: Image.asset(backgroundImages[index], fit: BoxFit.cover),
              );
            },
          ),
    );
  }

  @override
  void dispose() {
    _chatService.removerUsuarioOnline(widget.roomName);
    _messageController.dispose();
    _focusNode.dispose();
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
                return Text(' ($onlineCount online)');
              },
            ),
          ],
        ),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _selecionarFundo,
          ),
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(selectedBackground),
                  fit: BoxFit.cover,
                ),
              ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:
                              isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
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
    );
  }
}
