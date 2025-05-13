import 'package:flutter/material.dart';
import 'package:pheli_fla_app/widgets/news_card.dart';

class NoticiasPage extends StatelessWidget {
  final Future<List<Map<String, String>>> noticiascoluna;

  const NoticiasPage({Key? key, required this.noticiascoluna})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: noticiascoluna,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma notícia disponível.'));
        }

        final noticias = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: noticias.length,
          itemBuilder: (context, index) {
            final noticia = noticias[index];
            return NewsCard(
              titulo: noticia['titulo'] ?? '',
              imagem: noticia['imagem'] ?? '',
              link: noticia['link'] ?? '',
            );
          },
        );
      },
    );
  }
}
