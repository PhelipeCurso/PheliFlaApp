import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NoticiaDetalhePage extends StatelessWidget {
  final Map<String, String> noticia;

  const NoticiaDetalhePage({Key? key, required this.noticia}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(noticia['titulo'] ?? "Notícia"),
        backgroundColor: Colors.red[800],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem de Destaque
            if (noticia['imagem'] != null && noticia['imagem']!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: noticia['imagem']!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    noticia['titulo'] ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // Conteúdo da Notícia
                  Text(
                    noticia['conteudo'] ?? "Sem conteúdo disponível.",
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5, // Melhora a legibilidade
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