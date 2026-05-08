import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';

class GameDetailsPage extends StatelessWidget {
  final Game game;

  const GameDetailsPage({Key? key, required this.game}) : super(key: key);

  /// FUNÇÃO MELHORADA: Normaliza o nome removendo acentos e espaços
  String _normalizeStadiumId(String text) {
    String withDiacritics = 'àáâãäåòóôõöøèéêëìíîïùúûüÿñçÀÁÂÃÄÅÒÓÔÕÖØÈÉÊËÌÍÎÏÙÚÛÜÑÇ';
    String withoutDiacritics = 'aaaaaaooooooeeeeiiiiuuuuyncAAAAAAOOOOOOEEEEIIIIUUUUNC';

    String normalized = text.trim();

    // Substitui cada caractere com acento pelo seu equivalente sem acento
    for (int i = 0; i < withDiacritics.length; i++) {
      normalized = normalized.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }

    // Remove espaços e substitui por underline para bater com o banco
    return normalized.replaceAll(' ', '_');
  }

  Future<DocumentSnapshot> _getStadiumData() async {
    // Agora "Maracanã" vira "Maracana", garantindo que encontre no Firebase
    String stadiumId = _normalizeStadiumId(game.local);
    
    // Log para você conferir no Debug Console se o ID está correto
    debugPrint("ID Gerado para busca: $stadiumId");

    return await FirebaseFirestore.instance
        .collection('estadios')
        .doc(stadiumId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: _getStadiumData(),
      builder: (context, snapshot) {
        // Estado de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
        }

        Map<String, dynamic> stadiumData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          stadiumData = snapshot.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Detalhes da Partida"),
            backgroundColor: Colors.red[900],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. Header com validação de URL
                _buildStadiumHeader(context, stadiumData['fotoUrl']),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Últimos Confrontos
                      _buildSectionTitle("Últimos Confrontos"),
                      _buildH2HList(isDark, stadiumData['ultimosConfrontos'] ?? []),

                      const SizedBox(height: 24),

                      // 3. Estatísticas
                      _buildSectionTitle("Desempenho no ${game.local}"),
                      _buildStadiumStats(isDark, stadiumData),

                      const SizedBox(height: 24),

                      // 4. Curiosidades
                      _buildSectionTitle("Você sabia?"),
                      _buildCuriosityCard(isDark, stadiumData['curiosidades']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStadiumHeader(BuildContext context, String? fotoUrl) {
    final bool hasImage = fotoUrl != null && fotoUrl.isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            image: DecorationImage(
              image: NetworkImage(hasImage 
                ? fotoUrl 
                : "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Text(
            game.local,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildH2HList(bool isDark, List<dynamic> historico) {
    if (historico.isEmpty) return const Text("Sem histórico recente.");
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: historico.length,
        itemBuilder: (context, index) {
          final h = historico[index];
          Color cor = h['tipo'] == 'V' ? Colors.green : (h['tipo'] == 'E' ? Colors.orange : Colors.red);
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(h['tipo'] ?? '-', style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 20)),
                Text(h['placar'] ?? '', style: const TextStyle(fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStadiumStats(bool isDark, Map<String, dynamic> data) {
    int v = int.tryParse(data['vitoriasFla']?.toString() ?? '0') ?? 0;
    int e = int.tryParse(data['empatesFla']?.toString() ?? '0') ?? 0;
    int d = int.tryParse(data['derrotasFla']?.toString() ?? '0') ?? 0;
    int total = v + e + d;

    String getPerc(int val) => total == 0 ? "0%" : "${((val / total) * 100).toStringAsFixed(0)}%";

    return Card(
      elevation: 0,
      color: isDark ? Colors.white10 : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _statRow("Vitórias", "$v (${getPerc(v)})", Colors.green),
            _statRow("Empates", "$e (${getPerc(e)})", Colors.orange),
            _statRow("Derrotas", "$d (${getPerc(d)})", Colors.red),
            const Divider(),
            Text("Artilheiro: ${data['artilheiro'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String val, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(val, style: TextStyle(color: c, fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget _buildCuriosityCard(bool isDark, String? text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Text(text ?? "Nenhuma curiosidade disponível.", style: const TextStyle(fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}