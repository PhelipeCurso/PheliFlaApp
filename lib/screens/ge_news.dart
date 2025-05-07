// ge_news_widget.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as parser;

class GeNewsWidget extends StatefulWidget {
  const GeNewsWidget({Key? key}) : super(key: key);

  @override
  _GeNewsWidgetState createState() => _GeNewsWidgetState();
}

class _GeNewsWidgetState extends State<GeNewsWidget> {
  List<Map<String, String>> noticias = [];

  @override
  void initState() {
    super.initState();
    _buscarNoticias();
  }

  Future<void> _buscarNoticias() async {
    try {
      final response = await http.get(
        Uri.parse('https://ge.globo.com/futebol/times/flamengo/'),
      );
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('.feed-post-body');

        final novasNoticias =
            elements.take(10).map((element) {
              final titulo =
                  element.querySelector('.feed-post-link')?.text.trim() ??
                  'Sem título';
              final link =
                  element
                      .querySelector('.feed-post-link')
                      ?.attributes['href'] ??
                  '';
              final img = element.querySelector('img')?.attributes['src'] ?? '';

              return {
                'titulo': titulo,
                'link': link.startsWith('http') ? link : 'https:$link',
                'imagem': img,
              };
            }).toList();

        setState(() {
          noticias = novasNoticias;
        });
      }
    } catch (e) {
      print('Erro ao buscar notícias do GE: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias GE(Flamengo)'),
        backgroundColor: Colors.red[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: noticias.map((noticia) => _noticiaItem(noticia)).toList(),
      ),
    );
  }

  Widget _noticiaItem(Map<String, String> noticia) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(noticia['link']!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (noticia['imagem']!.isNotEmpty)
              Image.network(
                noticia['imagem']!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                noticia['titulo']!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
