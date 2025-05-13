import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

class ColunaDoFlaWidget extends StatefulWidget {
  const ColunaDoFlaWidget({Key? key}) : super(key: key);

  @override
  State<ColunaDoFlaWidget> createState() => _ColunaDoFlaWidgetState();
}

class _ColunaDoFlaWidgetState extends State<ColunaDoFlaWidget> {
  List<Map<String, String>> noticias = [];

  @override
  void initState() {
    super.initState();
    _buscarNoticias();
  }

  Future<void> _buscarNoticias() async {
    try {
      final response = await http.get(Uri.parse('https://colunadofla.com/'));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('.td-module-thumb');

        final novasNoticias =
            elements.take(10).map((element) {
              final link = element.querySelector('a')?.attributes['href'] ?? '';
              final imgElement = element.querySelector('img');
              final img =
                  imgElement?.attributes['data-src'] ??
                  imgElement?.attributes['src'] ??
                  '';
              final titulo = imgElement?.attributes['title'] ?? 'Sem título';

              return {'titulo': titulo, 'link': link, 'imagem': img};
            }).toList();

        setState(() {
          noticias = novasNoticias;
        });
      }
    } catch (e) {
      print('Erro ao buscar do Coluna do Fla: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coluna do Fla'),
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
