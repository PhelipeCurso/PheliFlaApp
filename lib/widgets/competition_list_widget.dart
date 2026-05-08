import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/games_service.dart';
import '../screens/GameDetailsPage.dart'; // Importe correto da nova tela

class CompetitionListWidget extends StatefulWidget {
  final String competicao;

  const CompetitionListWidget({Key? key, required this.competicao})
      : super(key: key);

  @override
  State<CompetitionListWidget> createState() => _CompetitionListWidgetState();
}

class _CompetitionListWidgetState extends State<CompetitionListWidget> {
  String selectedFilter = 'past'; // O filtro padrão inicial

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterButtons(),
        Expanded(
          child: StreamBuilder<List<Game>>(
            stream: GamesService().getGamesByCompetition(widget.competicao),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Erro ao carregar jogos."));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.red[800]),
                );
              }

              final allGames = snapshot.data ?? [];
              final now = DateTime.now();

              // 1. FILTRAGEM LOCAL
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

              // 2. ORDENAÇÃO DINÂMICA
              filteredGames.sort((a, b) {
                DateTime dateA = DateTime.tryParse(a.data) ?? DateTime(2000);
                DateTime dateB = DateTime.tryParse(b.data) ?? DateTime(2000);

                if (selectedFilter == 'future' || selectedFilter == 'today') {
                  return dateA.compareTo(dateB);
                } else {
                  return dateB.compareTo(dateA);
                }
              });

              if (filteredGames.isEmpty) {
                return const Center(
                  child: Text("Nenhum jogo nesta categoria."),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black26
          : Colors.grey[100],
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
        setState(() {
          selectedFilter = filter;
        });
      },
      selectedColor: Colors.red[800],
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87),
      ),
    );
  }

  // --- MÉTODO CORRIGIDO ABAIXO ---
  Widget _buildGameCard(Game game) {
    // Definimos as variáveis antes do return para o código ficar limpo
    String placarExibicao = game.concluido
        ? '${game.golsFlamengo} - ${game.golsAdversario}'
        : ' - ';

    String dataFormatada = "";
    try {
      DateTime dt = DateTime.parse(game.data);
      dataFormatada = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
    } catch (e) {
      dataFormatada = game.data;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // O InkWell fica dentro do Card para não estragar a elevação, 
      // ou fora se você quiser que o card inteiro reaja ao toque.
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailsPage(game: game),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                game.etapa.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTeam(game.escudotime, "Flamengo"),
                  Column(
                    children: [
                      Text(
                        placarExibicao,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white10 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "$dataFormatada • ${game.hora}",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildTeam(game.escudoAdversario, game.adversario),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red[800]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      game.local,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeam(String shield, String name) {
    return SizedBox(
      width: 85,
      child: Column(
        children: [
          Image.network(
            shield,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 50, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}