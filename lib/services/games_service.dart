import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';

class GamesService {
  static const String _baseDomain = 'projetoapi-production-a6f9.up.railway.app';

  /// Busca jogos com filtro opcional por competição.
  static Future<List<Game>> fetchGames({String? competicao}) async {
    Uri uri = Uri.https(_baseDomain, '/jogos');

    if (competicao != null && competicao.isNotEmpty) {
      uri = uri.replace(queryParameters: {'competicao': competicao});
    }

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('🔗 URL chamada: $uri');
      print('📦 Status code: ${response.statusCode}');
      print('📏 Tamanho do body: ${response.body.length}');
      print('📝 Resposta bruta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Game.fromJson(json)).toList();
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao buscar jogos: $e');
      return [];
    }
  }
}
