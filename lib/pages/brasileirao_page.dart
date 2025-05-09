import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/games_service.dart';

class BrasileiraoPage extends StatefulWidget {
  @override
  _BrasileiraoPageState createState() => _BrasileiraoPageState();
}

class _BrasileiraoPageState extends State<BrasileiraoPage> {
  List<Game> games = [];
  bool isLoading = true;

  Future<void> fetchData(String filter) async {
    setState(() {
      isLoading = true;
    });
    final now = DateTime.now();
    bool fetchUpcoming = filter == 'future';

    games = await GamesService.fetchGames(
      leagueId: 71,
      season: 2025,
      teamId: null, // <-- IMPORTANTE
      fetchUpcoming: false,
    );

    // Filtro adicional para mostrar apenas jogos de hoje, se necessário
    if (filter == 'today') {
      games =
          games.where((g) {
            final gameDate = DateTime.tryParse(g.date);
            return gameDate != null &&
                gameDate.day == now.day &&
                gameDate.month == now.month &&
                gameDate.year == now.year;
          }).toList();
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData('past');
  }

  @override
  Widget build(BuildContext context) {
    return _buildUI('Brasileirão Série A');
  }

  Widget _buildUI(String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => fetchData('past'),
                child: Text('Passados'),
              ),
              ElevatedButton(
                onPressed: () => fetchData('today'),
                child: Text('Hoje'),
              ),
              ElevatedButton(
                onPressed: () => fetchData('future'),
                child: Text('Futuros'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : games.isEmpty
                  ? Center(child: Text('Nenhum jogo encontrado.'))
                  : ListView.builder(
                    itemCount: games.length,
                    itemBuilder:
                        (context, index) => _buildGameCard(games[index]),
                  ),
        ),
      ],
    );
  }

  Widget _buildGameCard(Game g) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              g.league,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Image.network(
                      g.homeBadge,
                      width: 40,
                      errorBuilder: (_, __, ___) => Icon(Icons.shield),
                    ),
                    SizedBox(height: 4),
                    Text(g.homeTeam),
                  ],
                ),
                Text(
                  '${g.homeScore ?? '-'} x ${g.awayScore ?? '-'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: [
                    Image.network(
                      g.awayBadge,
                      width: 40,
                      errorBuilder: (_, __, ___) => Icon(Icons.shield),
                    ),
                    SizedBox(height: 4),
                    Text(g.awayTeam),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Data: ${g.date} às ${g.time}',
              style: TextStyle(fontSize: 13),
            ),
            if (g.venue.isNotEmpty)
              Text('Estádio: ${g.venue}', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
