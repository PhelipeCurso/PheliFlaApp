// lib/screens/canto_detalhes_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/canto_model.dart';

class CantoDetalhesScreen extends StatefulWidget {
  final CantoModel canto;
  const CantoDetalhesScreen({super.key, required this.canto});

  @override
  State<CantoDetalhesScreen> createState() => _CantoDetalhesScreenState();
}

class _CantoDetalhesScreenState extends State<CantoDetalhesScreen> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool isModoEstadio = false;
  bool isFavorito = false; // Dica: Integre com seu SharedPreferences/Firestore futuramente

  @override
  void initParent() {}

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Ouve as mudanças de estado do áudio para atualizar o botão de play/pause
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    WakelockPlus.disable(); // Força desligar o wakelock ao sair da tela
    super.dispose();
  }

  void _togglePlayPause() async {
    if (widget.canto.audioUrl.isEmpty) return;

    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.canto.audioUrl));
    }
  }

  void _toggleModoEstadio() {
    setState(() {
      isModoEstadio = !isModoEstadio;
    });

    if (isModoEstadio) {
      WakelockPlus.enable(); // Segura a tela ligada
    } else {
      WakelockPlus.disable(); // Libera o comportamento padrão
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cores dinâmicas baseadas no Modo Estádio
    final backgroundColor = isModoEstadio ? Colors.black : Colors.white;
    final textColor = isModoEstadio ? Colors.white : Colors.black87;
    final double fontSize = isModoEstadio ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.canto.titulo),
        backgroundColor: isModoEstadio ? Colors.grey[900] : const Color(0xFFC52026),
        foregroundColor: Colors.white,
        actions: [
          // Botão Favoritar
          IconButton(
            icon: Icon(isFavorito ? Icons.favorite : Icons.favorite_border, color: Colors.white),
            onPressed: () {
              setState(() {
                isFavorito = !isFavorito;
              });
            },
          ),
          // Botão Modo Estádio
          IconButton(
            icon: Icon(isModoEstadio ? Icons.stadium : Icons.stadium_outlined, color: isModoEstadio ? Colors.yellow : Colors.white),
            onPressed: _toggleModoEstadio,
          ),
        ],
      ),
      body: Column(
        children: [
          // Letra da Música com rolagem
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Center(
                child: Text(
                  widget.canto.letra,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    height: 1.6,
                    fontWeight: isModoEstadio ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          
          // Player de Áudio Inferior (Só aparece se houver áudio cadastrado)
          if (widget.canto.audioUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: isModoEstadio ? Colors.grey[900] : Colors.grey[100],
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: const Color(0xFFC52026),
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isPlaying ? 'Ouvindo referência...' : 'Ouvir canto',
                      style: TextStyle(
                        color: isModoEstadio ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}