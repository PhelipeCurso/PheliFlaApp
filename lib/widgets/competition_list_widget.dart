import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/games_service.dart';

class CompetitionListWidget extends StatefulWidget {
  final String competicao;

  const CompetitionListWidget({Key? key, required this.competicao}) : super(key: key);

  @override
  _CompetitionListWidgetState createState() => _CompetitionListWidgetState();
}

class _CompetitionListWidgetState extends State<CompetitionListWidget> {
  String selectedFilter = 'past'; // O filtro padrão inicial

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterButtons(),
        Expanded(
          // Substituímos o carregamento manual pelo StreamBuilder
          child: StreamBuilder<List<Game>>(
            stream: GamesService().getGamesByCompetition(widget.competicao),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Erro ao carregar jogos."));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.red[800]));
              }

              final allGames = snapshot.data ?? [];
              final now = DateTime.now();

              // Fazemos o filtro de data localmente com os dados que chegaram do Firebase
              final filteredGames = allGames.where((g) {
                try {
                  final gameDate = DateTime.parse(g.data);
                  final isSameDay = gameDate.day == now.day &&
                                    gameDate.month == now.month &&
                                    gameDate.year == now.year;

                  if (selectedFilter == 'today') {
                    return isSameDay;
                  } else if (selectedFilter == 'future') {
                    return gameDate.isAfter(now) && !isSameDay;
                  } else {
                    return gameDate.isBefore(now) && !isSameDay;
                  }
                } catch (e) {
                  return false;
                }
              }).toList();

              if (filteredGames.isEmpty) {
                return Center(child: Text("Nenhum jogo nesta categoria."));
              }

              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: filteredGames.length,
                itemBuilder: (context, index) => _buildGameCard(filteredGames[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _filterButton('Anteriores', 'past'),
          _filterButton('Hoje', 'today'),
          _filterButton('Próximos', 'future'),
        ],
      ),
    );
  }

  Widget _filterButton(String label, String filter) {
    bool isSelected = selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        // Agora o setState só muda o filtro visual, o StreamBuilder reage automaticamente
        setState(() {
          selectedFilter = filter;
        });
      },
      selectedColor: Colors.red[800],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildGameCard(Game game) {
    // Nova lógica para exibir o placar baseado nos campos do Firebase
    String placarExibicao = game.concluido 
        ? '${game.golsFlamengo} - ${game.golsAdversario}' 
        : ' - ';

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(game.etapa, 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeam(game.escudotime, "Flamengo"),
                Column(
                  children: [
                    Text(
                      placarExibicao, 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(game.hora, style: TextStyle(color: Colors.grey)),
                  ],
                ),
                _buildTeam(game.escudoAdversario, game.adversario),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.red[800]),
                SizedBox(width: 4),
                Flexible(
                  child: Text(game.local, 
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTeam(String shield, String name) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Image.network(
            shield, 
            width: 50, 
            height: 50, 
            errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 50)
          ),
          SizedBox(height: 4),
          Text(
            name, 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}