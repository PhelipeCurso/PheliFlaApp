import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

class HomeService {
  final FirebaseFirestore _firestore;

  HomeService([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, String>>> fetchNoticiasPheliFla() async {
    try {
      final snapshot =
          await _firestore
              .collection('noticias')
              .orderBy('dataCriacao', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'titulo': data['titulo']?.toString() ?? 'Sem título',
          'link': data['id']?.toString() ?? '',
          'imagem': data['imagemUrl']?.toString() ?? '',
          'conteudo': data['conteudo']?.toString() ?? '',
          'autor': data['autor']?.toString() ?? 'Redação PheliFla',
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro Firestore PheliFla: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> fetchNoticiasGE() async {
    try {
      final response = await http.get(
        Uri.parse('https://ge.globo.com/futebol/times/flamengo/'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (response.statusCode != 200) {
        return [];
      }

      final document = htmlParser.parse(response.body);
      final elements = document.querySelectorAll('.feed-post-body');
      final resultados = <Map<String, String>>[];

      for (final element in elements) {
        final linkElement = element.querySelector('.feed-post-link');
        final link = linkElement?.attributes['href'] ?? '';
        if (!link.contains('globo.com')) continue;

        final titulo = linkElement?.text.trim() ?? 'Sem título';
        final img =
            element.parent?.querySelector('img')?.attributes['src'] ?? '';

        resultados.add({
          'titulo': titulo,
          'link': link.startsWith('http') ? link : 'https:$link',
          'imagem': img,
        });

        if (resultados.length >= 10) break;
      }

      return resultados;
    } catch (e) {
      debugPrint('Erro ao buscar notícias GE: $e');
      return [];
    }
  }
}
