import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';

class GamesService {
  static const String _apiKey = 'f55e7b3b87e1e2f5cbec51dacad2d32d';
  static const String _baseUrl = 'v3.football.api-sports.io';

  static Future<List<Game>> fetchGames({
    required int leagueId,
    required int season,
    int? teamId, // deixe como null para buscar todos os times
    bool fetchUpcoming = false,
  }) async {
    final queryParams = {
      fetchUpcoming ? 'next' : 'last': '10',
      'league': leagueId.toString(),
      'season': season.toString(),
    };

    if (teamId != null) {
      queryParams['team'] = teamId.toString();
    }

    final url = Uri.https(_baseUrl, 'fixtures', queryParams);

    try {
      final response = await http.get(
        url,
        headers: {'x-apisports-key': _apiKey, 'Accept': 'application/json'},
      );
      print('URL chamada: $url'); // 🐛 Verifica se a URL está correta
      print('Status code: ${response.statusCode}'); // ✅ Mostra se deu 200
      print('Resposta bruta: ${response.body}'); // 📦 Mostra o JSON completo

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fixtures = data['response'] as List;
        return fixtures.map((f) => Game.fromApiFootballJson(f)).toList();
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro na API-Football: $e');
      return [];
    }
  }
}
