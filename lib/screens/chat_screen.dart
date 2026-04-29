import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/chat_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? nomeDaSala;
  String selectedBackground = 'assets/images/fundos/PheliFlafundo.png';

  final List<String> backgroundImages = const [
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
    WidgetsBinding.instance.addObserver(this);
    _loadSavedBackground();
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    await _chatService.criarSalaSeNaoExistir(widget.roomName);
    _setUsuarioOnline(true);
    _carregarNomeSala();
  }

  void _setUsuarioOnline(bool isOnline) {
    if (isOnline) {
      _chatService.adicionarUsuarioOnline(
        widget.roomName,
        widget.nomeUsuario,
        widget.photoUrl,
      );
    } else {
      _chatService.removerUsuarioOnline(widget.roomName);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUsuarioOnline(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _setUsuarioOnline(false);
    }
  }

  Future<void> _loadSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBg = prefs.getString('chatBackground');
    if (savedBg != null && backgroundImages.contains(savedBg) && mounted) {
      setState(() => selectedBackground = savedBg);
    }
  }

  Future<void> _carregarNomeSala() async {
    final nome = await _chatService.buscarNomeSala(widget.roomName);
    if (mounted) setState(() => nomeDaSala = nome);
  }

  void _selecionarFundo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: backgroundImages.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (_, index) {
          final bg = backgroundImages[index];
          return GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('chatBackground', bg);
              if (mounted) setState(() => selectedBackground = bg);
              Navigator.pop(context);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(bg, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUsuarioOnline(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        elevation: 2,
        title: Row(
          children: [
            Expanded(
              child: Text(
                nomeDaSala ?? 'Carregando...',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildOnlineCounter(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            tooltip: 'Trocar Fundo',
            onPressed: _selecionarFundo,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _setUsuarioOnline(false);
              await _auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(selectedBackground),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _buildMessagesStream(currentUser?.uid)),
              ChatInputField(
                onSendMessage: (text) => _chatService.enviarMensagem(
                  widget.roomName,
                  text,
                  widget.nomeUsuario,
                  widget.photoUrl,
                ),
                onSendAudio: (path) => _chatService.enviarAudio(
                  widget.roomName,
                  path,
                  widget.nomeUsuario,
                  widget.photoUrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineCounter() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(widget.roomName)
          .collection('usersOnline')
          .snapshots(),
      builder: (context, snapshot) {
        final onlineCount = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
              const SizedBox(width: 4),
              Text(
                '$onlineCount',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesStream(String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(widget.roomName)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final messages = snapshot.data?.docs ?? [];
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (ctx, index) {
            final msgData = messages[index].data() as Map<String, dynamic>;
            final isMe = msgData['userId'] == currentUserId;
            return MessageBubble(msgData: msgData, isMe: isMe);
          },
        );
      },
    );
  }
}

// --- INPUT DE MENSAGEM COM SUPORTE A ÁUDIO ---

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String) onSendAudio;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    required this.onSendAudio,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _showMic = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) {
        setState(() => _showMic = _controller.text.isEmpty);
      }
    });
  }

  void _submitText() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print("Erro ao iniciar gravação: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        widget.onSendAudio(path);
      }
    } catch (e) {
      print("Erro ao parar gravação: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white.withOpacity(0.95),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isRecording,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: _isRecording ? '🎤 Gravando áudio...' : 'Digite sua mensagem...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: (_) => _showMic ? _startRecording() : null,
            onLongPressEnd: (_) => _showMic ? _stopRecording() : null,
            child: CircleAvatar(
              backgroundColor: _isRecording ? Colors.green : Colors.red[900],
              radius: 24,
              child: IconButton(
                icon: Icon(
                  _showMic ? (_isRecording ? Icons.mic : Icons.mic_none) : Icons.send,
                  color: Colors.white,
                ),
                onPressed: _showMic ? null : _submitText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- BOLHA DE MENSAGEM ---

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msgData;
  final bool isMe;

  const MessageBubble({super.key, required this.msgData, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bool isAudio = msgData['type'] == 'audio';
    final hasPhoto = msgData['photoUrl'] != null && msgData['photoUrl'].toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(hasPhoto, msgData['photoUrl']),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: isMe ? 40 : 8, right: isMe ? 8 : 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.red[800] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(msgData['userName'] ?? 'Usuário',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red[900])),
                    const SizedBox(height: 4),
                  ],
                  
                  // AQUI É A MÁGICA: CHAMA O PLAYER SE FOR ÁUDIO!
                  if (isAudio && msgData['mediaUrl'] != null)
                    AudioPlayerWidget(url: msgData['mediaUrl'], isMe: isMe)
                  else
                    Text(
                      msgData['text'] ?? '',
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                    ),

                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msgData['createdAt']),
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool hasPhoto, String? url) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: hasPhoto 
          ? NetworkImage(url!) 
          : const AssetImage('assets/images/Gaming.png') as ImageProvider,
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate().toLocal();
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }
} // <-- AQUI FECHA A MESSAGE BUBBLE!

// --- WIDGET DO PLAYER DE ÁUDIO (AGORA SEPARADO CORRETAMENTE) ---

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const AudioPlayerWidget({super.key, required this.url, required this.isMe});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Ouvir mudanças de estado (play/pause)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    // Ouvir duração total
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    // Ouvir posição atual
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: widget.isMe ? Colors.white : Colors.red[900],
            size: 35,
          ),
          onPressed: () async {
            if (_isPlaying) {
              await _audioPlayer.pause();
            } else {
              await _audioPlayer.play(UrlSource(widget.url));
            }
          },
        ),
        Text(
          "${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}",
          style: TextStyle(color: widget.isMe ? Colors.white70 : Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}