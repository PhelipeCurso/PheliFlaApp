import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Modelo estruturado de Comentário
class ComentarioModel {
  final String nomeUsuario;
  final String fotoUsuario;
  final String texto;
  final Timestamp dataCriacao;

  ComentarioModel({
    required this.nomeUsuario,
    required this.fotoUsuario,
    required this.texto,
    required this.dataCriacao,
  });

  factory ComentarioModel.fromFirestore(Map<String, dynamic> data) {
    return ComentarioModel(
      nomeUsuario: data['nomeUsuario'] ?? 'Usuário Rubro-Negro',
      fotoUsuario: data['fotoUsuario'] ?? '',
      texto: data['texto'] ?? '',
      dataCriacao: data['dataCriacao'] ?? Timestamp.now(),
    );
  }
}

class NoticiaDetalhePage extends StatefulWidget {
  final Map<String, String> noticia;

  const NoticiaDetalhePage({Key? key, required this.noticia}) : super(key: key);

  @override
  State<NoticiaDetalhePage> createState() => _NoticiaDetalhePageState();
}

class _NoticiaDetalhePageState extends State<NoticiaDetalhePage> {
  bool _foiCurtido = false;
  int _quantidadeCurtidas = 0; // Estado local para renderização rápida

  final TextEditingController _commentController = TextEditingController();
  final User? _usuarioLogado = FirebaseAuth.instance.currentUser;
  late String _noticiaId;

  @override
  void initState() {
    super.initState();

    // Gerando o ID seguro baseado na origem da notícia
    String idOriginal = widget.noticia['link'] ?? widget.noticia['id'] ?? '';
    String titulo = widget.noticia['titulo'] ?? '';

    if (idOriginal.contains('http://') ||
        idOriginal.contains('https://') ||
        idOriginal.isEmpty) {
      if (titulo.isNotEmpty) {
        var bytes = utf8.encode(titulo);
        _noticiaId = sha256.convert(bytes).toString();
      } else {
        _noticiaId = "noticia_sem_identificacao";
      }
    } else {
      _noticiaId = idOriginal;
    }

    // Carrega o estado inicial das curtidas do banco de dados
    _verificarEObterCurtidas();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- BUSCA INICIAL DE CURTIDAS DO BANCO ---
  Future<void> _verificarEObterCurtidas() async {
    if (_noticiaId.isEmpty || _usuarioLogado == null) return;

    try {
      final curtidasSnapshot =
          await FirebaseFirestore.instance
              .collection('noticias')
              .doc(_noticiaId)
              .collection('curtidas')
              .get();

      // Verifica se o UID do usuário atual está na lista de quem curtiu
      final usuarioCurtiu = curtidasSnapshot.docs.any(
        (doc) => doc.id == _usuarioLogado.uid,
      );

      setState(() {
        _quantidadeCurtidas = curtidasSnapshot.docs.length;
        _foiCurtido = usuarioCurtiu;
      });
    } catch (e) {
      debugPrint("Erro ao buscar curtidas: $e");
    }
  }

  // --- ALTERNAR CURTIDA (PERSISTÊNCIA) ---
  Future<void> _alternarCurtida() async {
    if (_usuarioLogado == null || _noticiaId.isEmpty) return;

    final docCurtidaRef = FirebaseFirestore.instance
        .collection('noticias')
        .doc(_noticiaId)
        .collection('curtidas')
        .doc(_usuarioLogado.uid); // O ID do documento é o UID do usuário

    // Atualiza a UI imediatamente para dar sensação de fluidez (Optimistic Update)
    setState(() {
      if (_foiCurtido) {
        _foiCurtido = false;
        _quantidadeCurtidas--;
      } else {
        _foiCurtido = true;
        _quantidadeCurtidas++;
      }
    });

    try {
      if (_foiCurtido) {
        // Se agora está marcado como curtido, salva o documento no banco
        await docCurtidaRef.set({
          'dataCurtida': FieldValue.serverTimestamp(),
          'usuarioNome': _usuarioLogado.displayName ?? "Usuário PheliFla",
        });
      } else {
        // Se descurtiu, remove o documento do banco
        await docCurtidaRef.delete();
      }
    } catch (e) {
      debugPrint("Erro ao atualizar curtida no Firebase: $e");
      // Caso dê erro, desfaz a alteração visual para não enganar o usuário
      _verificarEObterCurtidas();
    }
  }

  // --- ENVIAR COMENTÁRIO PARA O FIRESTORE ---
  Future<void> _adicionarComentario() async {
    final textoComentario = _commentController.text.trim();
    if (textoComentario.isEmpty) return;

    if (_noticiaId.isEmpty || _noticiaId == "noticia_sem_identificacao") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não é possível comentar nesta notícia.")),
      );
      return;
    }

    final String nome = _usuarioLogado?.displayName ?? "Usuário PheliFla";
    final String foto = _usuarioLogado?.photoURL ?? "";

    try {
      await FirebaseFirestore.instance
          .collection('noticias')
          .doc(_noticiaId)
          .collection('comentarios')
          .add({
            'nomeUsuario': nome,
            'fotoUsuario': foto,
            'texto': textoComentario,
            'dataCriacao': FieldValue.serverTimestamp(),
          });

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("ERRO AO SALVAR COMENTÁRIO: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFC62828)),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.noticia['titulo'] ?? "Notícia")),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem de Destaque
              if (widget.noticia['imagem'] != null &&
                  widget.noticia['imagem']!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.noticia['imagem']!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      widget.noticia['titulo'] ?? "",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Fonte
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Fonte: ${widget.noticia['autor'] ?? 'Redação PheliFla'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    // Conteúdo
                    Text(
                      widget.noticia['conteudo'] ?? "Sem conteúdo disponível.",
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),

                    // --- SEÇÃO DE INTERAÇÃO (CURTIDA ATUALIZADA) ---
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _foiCurtido
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _foiCurtido ? Colors.red : Colors.grey,
                          ),
                          onPressed: _alternarCurtida,
                        ),
                        Text(
                          _quantidadeCurtidas == 0
                              ? "Seja o primeiro a curtir"
                              : "$_quantidadeCurtidas ${_quantidadeCurtidas == 1 ? 'curtida' : 'curtidas'}",
                          style: TextStyle(
                            color: _foiCurtido ? Colors.red : Colors.grey,
                            fontWeight:
                                _foiCurtido
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    // --- SEÇÃO DE COMENTÁRIOS ---
                    const Text(
                      "Comentários",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Deixe um breve comentário...",
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.red),
                          onPressed: _adicionarComentario,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- LISTA DE COMENTÁRIOS VIA STREAMBUILDER ---
                    if (_noticiaId.isEmpty)
                      const Text(
                        "Comentários indisponíveis.",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('noticias')
                                .doc(_noticiaId)
                                .collection('comentarios')
                                .orderBy('dataCriacao', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.red,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Text(
                              "Nenhum comentário ainda. Seja o primeiro!",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final coment = ComentarioModel.fromFirestore(
                                data,
                              );

                              return Card(
                                color: const Color(0xFF1E1E24),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[700],
                                    backgroundImage:
                                        coment.fotoUsuario.isNotEmpty
                                            ? NetworkImage(coment.fotoUsuario)
                                            : const AssetImage(
                                                  'assets/images/Gaming.png',
                                                )
                                                as ImageProvider,
                                  ),
                                  title: Text(
                                    coment.nomeUsuario,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      coment.texto,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
