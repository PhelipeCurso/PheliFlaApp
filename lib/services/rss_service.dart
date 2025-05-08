import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:html/parser.dart' as htmlParser;

String? extrairImagem(String html) {
  final document = htmlParser.parse(html);
  final imgTag = document.querySelector('img');
  return imgTag?.attributes['src'];
}

Future<List<Map<String, String>>> fetchColunaFlaRSS() async {
  final response = await http.get(Uri.parse('https://colunadofla.com/feed/'));

  if (response.statusCode == 200) {
    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.map((item) {
      final title = item.findElements('title').first.text;
      final link = item.findElements('link').first.text;
      final description = item.findElements('description').first.text;

      final contentEncoded = item
          .findElements('content:encoded')
          .map((e) => e.text)
          .firstWhere((e) => e.isNotEmpty, orElse: () => '');

      // Fallback: usa description se content estiver vazio
      final html = contentEncoded.isNotEmpty ? contentEncoded : description;
      final imageUrl = extrairImagem(html);

      print('Título: $title');
      print('Imagem extraída: ${imageUrl ?? 'Nenhuma imagem encontrada'}');

      return {
        'titulo': title,
        'link': link,
        'imagem': imageUrl ?? '', // String não nula
      };
    }).toList();
  } else {
    throw Exception('Erro ao buscar feed RSS');
  }
}
