import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../services/games_service.dart';

class LibertadoresPage extends StatefulWidget {
  @override
  _LibertadoresPageState createState() => _LibertadoresPageState();
}

class _LibertadoresPageState extends State<LibertadoresPage> {
  List<Game> games = [];
  bool isLoading = true;
  String selectedFilter = 'past';


  Future<void> fetchData(String filter) async {
    setState(() {
      isLoading = true;
      selectedFilter = filter;
    });

    final now = DateTime.now();
    //games = await GamesService.fetchGames(competicao: 'libertadores');
    final allGames = await GamesService.fetchGames(competicao: 'libertadores');

    games = switch (filter) {
      'today' =>
        allGames.where((g) {
          try {
            final gameDate = DateTime.parse(g.data);
            return gameDate.day == now.day &&
                gameDate.month == now.month &&
                gameDate.year == now.year;
          } catch (_) {
            return false;
          }
        }).toList(),
      'future' =>
        allGames.where((g) {
          try {
            final gameDate = DateTime.parse(g.data);
            return gameDate.isAfter(now);
          } catch (_) {
            return false;
          }
        }).toList(),
      _ =>
        allGames.where((g) {
          try {
            final gameDate = DateTime.parse(g.data);
            return gameDate.isBefore(now);
          } catch (_) {
            return false;
          }
        }).toList(),
    };

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchData('past');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterButtons(),
        Expanded(
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : games.isEmpty
                  ? Center(child: Text('Nenhum jogo encontrado.'))
                  : _buildGroupedList(),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    final filters = {'past': 'Todos', 'today': 'Hoje', 'future': 'Futuros'};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children:
            filters.entries.map((entry) {
              final isSelected = selectedFilter == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) => fetchData(entry.key),
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: StadiumBorder(),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildGroupedList() {
    Map<String, List<Game>> grouped = {};
    for (var game in games) {
      grouped.putIfAbsent(game.data, () => []).add(game);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String date = sortedKeys[index];
        List<Game> dayGames = grouped[date]!;
        final formattedDate = _formatDate(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ...dayGames.map(_buildGameCard).toList(),
          ],
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(parsed);
    } catch (_) {
      return date;
    }
  }

  Widget _buildGameCard(Game g) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTeamLogo(imageUrl: g.escudotime, teamName: 'Flamengo'),
                SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      g.placar ?? 'x',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Placar', style: TextStyle(fontSize: 12)),
                  ],
                ),
                SizedBox(width: 12),
                _buildTeamLogo(
                  imageUrl: g.escudoAdversario,
                  teamName: g.adversario ?? 'Adversário',
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              g.competicao,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            Divider(height: 20),
            _buildRow(Icons.access_time, 'Horário', g.hora ?? 'A definir'),
            _buildRow(Icons.location_on, 'Local', g.local),
            _buildRow(Icons.sports_soccer, 'Competição', g.competicao),
            _buildRow(
              Icons.flag,
              "Etapa",
              g.etapa ?? 'Indefinida',
              color: _colorByStage(g.etapa ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo({required String? imageUrl, required String teamName}) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  )
                  : Icon(Icons.shield, size: 48),
        ),
        SizedBox(height: 4),
        Text(teamName, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? theme.iconTheme.color),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color ?? theme.textTheme.bodyMedium?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorByStage(String etapa) {
    switch (etapa.toLowerCase()) {
      case 'grupo':
        return Colors.blue;
      case 'quartas':
        return Colors.orange;
      case 'semifinal':
        return Colors.deepPurple;
      case 'final':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}
