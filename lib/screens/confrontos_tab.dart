import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import 'package:fl_chart/fl_chart.dart';

class ConfrontosTab extends StatelessWidget {
  final Game game;

  const ConfrontosTab({Key? key, required this.game}) : super(key: key);

  Future<DocumentSnapshot> _getConfrontoData() {
    return FirebaseFirestore.instance
        .collection('confrontos')
        .doc(game.adversario.toLowerCase())
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getConfrontoData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.red)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text("Histórico contra este adversário não cadastrado."),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> ultimosResultados = data['ultimos_resultados'] ?? [];

        return Scaffold(
          backgroundColor: Colors.white, // Resolve o fundo preto
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Retrospecto Geral"),
                const SizedBox(height: 16),
                _buildStatsGrid(data),

                // CHAMADA DO GRÁFICO INSERIDA AQUI PARA PREENCHER O ESPAÇO
                const SizedBox(height: 20),
                _buildConfrontoChart(data),
                const SizedBox(height: 20),

                _buildSectionTitle("Gols Marcados"),
                _buildGolsCard(data),

                const SizedBox(height: 24),
                _buildSectionTitle("Últimos 5 Jogos"),
                const SizedBox(height: 12),
                _buildRecentGamesList(ultimosResultados),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        decoration: TextDecoration.none, // Resolve sublinhado amarelo
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem("Vitórias", data['vitorias'].toString(), Colors.green[50]!, Colors.green[700]!),
        _buildStatItem("Empates", data['empates'].toString(), Colors.orange[50]!, Colors.orange[700]!),
        _buildStatItem("Derrotas", data['derrotas'].toString(), Colors.red[50]!, Colors.red[700]!),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color bgColor, Color textColor) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildGolsCard(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildGolsRow("Gols do Flamengo", data['gols_marcados'].toString(), Colors.red[800]!),
            const Divider(height: 20),
            _buildGolsRow("Gols do Adversário", data['gols_sofridos'].toString(), Colors.grey[600]!),
          ],
        ),
      ),
    );
  }

  Widget _buildGolsRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildConfrontoChart(Map<String, dynamic> data) {
    double vitorias = double.tryParse(data['vitorias'].toString()) ?? 0;
    double empates = double.tryParse(data['empates'].toString()) ?? 0;
    double derrotas = double.tryParse(data['derrotas'].toString()) ?? 0;
    double total = vitorias + empates + derrotas;

    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.red[900], // Flamengo
                  value: vitorias,
                  title: '${((vitorias / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.grey[600], // Empates
                  value: empates,
                  title: '${((empates / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.black, // Adversário
                  value: derrotas,
                  title: '${((derrotas / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem("Flamengo", Colors.red[900]!),
            const SizedBox(width: 15),
            _buildLegendItem("Empates", Colors.grey[600]!),
            const SizedBox(width: 15),
            _buildLegendItem(game.adversario, Colors.black),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentGamesList(List<dynamic> resultados) {
    if (resultados.isEmpty || resultados.every((element) => element == "")) {
      return const Text("Sem dados recentes.", style: TextStyle(fontStyle: FontStyle.italic));
    }

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: resultados.length,
        itemBuilder: (context, index) {
          if (resultados[index] == "") return const SizedBox.shrink();
          String res = resultados[index].toString().toUpperCase();
          Color color = res.startsWith('V') ? Colors.green : (res.startsWith('D') ? Colors.red : Colors.orange);

          return Container(
            width: 65,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(res.split(' ')[0], style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                Text(res.contains(' ') ? res.split(' ')[1] : "", style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}