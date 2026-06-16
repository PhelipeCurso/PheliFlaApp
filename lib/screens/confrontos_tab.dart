import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/game.dart';

// ═══════════════════════════════════════════════════════════════════
// CONSTANTES
// ═══════════════════════════════════════════════════════════════════

abstract class _K {
  static const String colConfrontos = 'confrontos';
}

// ═══════════════════════════════════════════════════════════════════
// SERVIÇO DE DADOS
// ═══════════════════════════════════════════════════════════════════

class _ConfrontoService {
  static final _firestore = FirebaseFirestore.instance;

  static String _normalizeId(String text) {
    const withAccents    = 'àáâãäåòóôõöøèéêëìíîïùúûüÿñçÀÁÂÃÄÅÒÓÔÕÖØÈÉÊËÌÍÎÏÙÚÛÜÑÇ';
    const withoutAccents = 'aaaaaaooooooeeeeiiiiuuuuyncAAAAAAOOOOOOEEEEIIIIUUUUNC';

    var result = text.trim().toLowerCase();
    for (var i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i].toLowerCase());
    }
    return result.replaceAll(' ', '_');
  }

  static Future<Map<String, dynamic>> fetchConfronto(String adversario) async {
    final id = _normalizeId(adversario);
    debugPrint('⚔️ Buscando confronto com ID: $id');
    final doc = await _firestore.collection(_K.colConfrontos).doc(id).get();
    return doc.exists ? (doc.data() ?? {}) : {};
  }

  static int parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

// ═══════════════════════════════════════════════════════════════════
// MODEL LOCAL
// ═══════════════════════════════════════════════════════════════════

class _ConfrontoData {
  final int vitorias;
  final int empates;
  final int derrotas;
  final int golsMarcados;
  final int golsSofridos;
  final List<String> ultimosResultados;

  int get total => vitorias + empates + derrotas;

  const _ConfrontoData({
    required this.vitorias,
    required this.empates,
    required this.derrotas,
    required this.golsMarcados,
    required this.golsSofridos,
    required this.ultimosResultados,
  });

  factory _ConfrontoData.fromMap(Map<String, dynamic> map) {
    final raw = map['ultimos_resultados'] as List<dynamic>? ?? [];
    return _ConfrontoData(
      vitorias:          _ConfrontoService.parseInt(map['vitorias']),
      empates:           _ConfrontoService.parseInt(map['empates']),
      derrotas:          _ConfrontoService.parseInt(map['derrotas']),
      golsMarcados:      _ConfrontoService.parseInt(map['gols_marcados']),
      golsSofridos:      _ConfrontoService.parseInt(map['gols_sofridos']),
      ultimosResultados: raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ═══════════════════════════════════════════════════════════════════

class ConfrontosTab extends StatefulWidget {
  final Game game;
  const ConfrontosTab({super.key, required this.game});

  @override
  State<ConfrontosTab> createState() => _ConfrontosTabState();
}

class _ConfrontosTabState extends State<ConfrontosTab> {
  late Future<Map<String, dynamic>> _confrontoFuture;

  @override
  void initState() {
    super.initState();
    _confrontoFuture = _ConfrontoService.fetchConfronto(widget.game.adversario);
  }

  void _retry() => setState(() {
        _confrontoFuture = _ConfrontoService.fetchConfronto(widget.game.adversario);
      });

  @override
  Widget build(BuildContext context) {
    // ── FIX DARK MODE ─────────────────────────────────────────────
    // Abas dentro de TabBarView/PageView NÃO herdam o backgroundColor
    // do Scaffold pai. A solução é usar Material (ou ColoredBox) com
    // a cor extraída do Theme — nunca um Scaffold interno com cor fixa.
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      // Material.color é o equivalente ao Scaffold.backgroundColor para abas.
      // colorScheme.surface já respeita dark/light automaticamente.
      color: colorScheme.surface,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _confrontoFuture,
        builder: (context, snapshot) {
          // ── Loading ─────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          // ── Erro ────────────────────────────────────────────────
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _retry);
          }

          // ── Vazio ───────────────────────────────────────────────
          final map = snapshot.data ?? {};
          if (map.isEmpty) {
            return _EmptyState(adversario: widget.game.adversario);
          }

          final data = _ConfrontoData.fromMap(map);

          return RefreshIndicator(
            color:     Colors.red,
            onRefresh: () async => _retry(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Retrospecto Geral'),
                  const SizedBox(height: 14),
                  _StatsGrid(data: data),

                  const SizedBox(height: 24),

                  const _SectionTitle(title: 'Distribuição de Resultados'),
                  const SizedBox(height: 14),
                  _ConfrontoChart(data: data, adversario: widget.game.adversario),

                  const SizedBox(height: 24),

                  const _SectionTitle(title: 'Gols Marcados'),
                  const SizedBox(height: 14),
                  _GolsCard(data: data),

                  const SizedBox(height: 24),

                  const _SectionTitle(title: 'Últimos 5 Jogos'),
                  const SizedBox(height: 14),
                  _RecentGamesList(resultados: data.ultimosResultados),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SUB-WIDGETS — lêem isDark via Theme.of(context)
// ═══════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ── Grid V/E/D ────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _ConfrontoData data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Vitórias', value: data.vitorias.toString(), color: Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Empates',  value: data.empates.toString(),  color: Colors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Derrotas', value: data.derrotas.toString(), color: Colors.red)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color:        isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color: isDark ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.9),
              )),
        ],
      ),
    );
  }
}

// ── Gráfico ───────────────────────────────────────────────────────

class _ConfrontoChart extends StatelessWidget {
  final _ConfrontoData data;
  final String         adversario;
  const _ConfrontoChart({required this.data, required this.adversario});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.total == 0) {
      return const _EmptyInfo(message: 'Sem dados suficientes para o gráfico.');
    }

    final total = data.total.toDouble();
    String perc(int v) => '${((v / total) * 100).toStringAsFixed(0)}%';

    const titleStyle = TextStyle(
        fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white);

    // ── FIX: cor de fundo do card do gráfico via colorScheme ──────
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sectionsSpace:     4,
                centerSpaceRadius: 44,
                sections: [
                  if (data.vitorias > 0)
                    PieChartSectionData(color: Colors.green,    value: data.vitorias.toDouble(), title: perc(data.vitorias), radius: 54, titleStyle: titleStyle),
                  if (data.empates > 0)
                    PieChartSectionData(color: Colors.orange,   value: data.empates.toDouble(),  title: perc(data.empates),  radius: 54, titleStyle: titleStyle),
                  if (data.derrotas > 0)
                    PieChartSectionData(color: Colors.red[800]!, value: data.derrotas.toDouble(), title: perc(data.derrotas), radius: 54, titleStyle: titleStyle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20, runSpacing: 8, alignment: WrapAlignment.center,
            children: [
              const _LegendItem(label: 'Flamengo', color: Colors.green),
              const _LegendItem(label: 'Empates',  color: Colors.orange),
              _LegendItem(label: adversario, color: Colors.red[800]!),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color  color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87)),
      ],
    );
  }
}

// ── Card de gols ──────────────────────────────────────────────────

class _GolsCard extends StatelessWidget {
  final _ConfrontoData data;
  const _GolsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── FIX: usa colorScheme.surfaceContainerHighest no dark ──────
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _GolsRow(label: 'Gols do Flamengo',  value: data.golsMarcados.toString(), color: Colors.red[800]!),
            Divider(height: 24, color: isDark ? Colors.white12 : Colors.black12),
            _GolsRow(
              label: 'Gols do Adversário',
              value: data.golsSofridos.toString(),
              color: isDark ? Colors.white54 : Colors.grey[600]!,
            ),
            const SizedBox(height: 16),
            _GolsBar(fla: data.golsMarcados, adv: data.golsSofridos),
          ],
        ),
      ),
    );
  }
}

class _GolsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _GolsRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _GolsBar extends StatelessWidget {
  final int fla;
  final int adv;
  const _GolsBar({required this.fla, required this.adv});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total  = fla + adv;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('FLA', style: TextStyle(fontSize: 11, color: Colors.red[800], fontWeight: FontWeight.bold)),
            Text('ADV', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Flexible(flex: fla, child: ColoredBox(color: Colors.red[800]!)),
                Flexible(flex: adv, child: ColoredBox(color: isDark ? Colors.white24 : Colors.grey[400]!)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Últimos jogos ─────────────────────────────────────────────────

class _RecentGamesList extends StatelessWidget {
  final List<String> resultados;
  const _RecentGamesList({required this.resultados});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (resultados.isEmpty) {
      return const _EmptyInfo(message: 'Sem dados recentes disponíveis.');
    }

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:       resultados.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final raw    = resultados[i].toUpperCase();
          final tipo   = raw.split(' ').first;
          final placar = raw.contains(' ') ? raw.split(' ').skip(1).join(' ') : '';
          final cor    = _cor(tipo);

          return Container(
            width: 68,
            decoration: BoxDecoration(
              color:        cor.withValues(alpha: isDark ? 0.20 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: cor.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tipo,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 20)),
                if (placar.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(placar,
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _cor(String tipo) => switch (tipo) {
        'V' => Colors.green,
        'E' => Colors.orange,
        _   => Colors.red,
      };
}

// ═══════════════════════════════════════════════════════════════════
// ESTADOS AUXILIARES
// ═══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String adversario;
  const _EmptyState({required this.adversario});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_rounded,
                size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text('Histórico não encontrado',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 8),
            Text('Ainda não temos dados de confrontos contra $adversario.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black38)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final textColor  = isDark ? Colors.white60 : Colors.grey[700];
    final iconColor  = isDark ? Colors.white38 : Colors.grey[400];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar o histórico de confrontos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInfo extends StatelessWidget {
  final String message;
  const _EmptyInfo({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: isDark ? Colors.white38 : Colors.black26),
          const SizedBox(width: 8),
          Text(message,
              style: TextStyle(
                  fontStyle: FontStyle.italic, fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black38)),
        ],
      ),
    );
  }
}