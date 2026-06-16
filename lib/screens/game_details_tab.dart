import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/game.dart';

// ═══════════════════════════════════════════════════════════════════
// CONSTANTES — evita magic strings espalhadas pelo código
// ═══════════════════════════════════════════════════════════════════

abstract class _K {
  // AdMob — ID de teste oficial do Google (troque pelo real antes de publicar)
  static const String adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  // Firestore
  static const String colEstadios = 'estadios';

  // Imagem fallback para estádios sem foto
  static const String fallbackStadiumImg =
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000';
}

// ═══════════════════════════════════════════════════════════════════
// SERVIÇO DE DADOS — separa lógica de negócio da UI
// ═══════════════════════════════════════════════════════════════════

class _StadiumService {
  static final _firestore = FirebaseFirestore.instance;

  /// Normaliza o nome do estádio para usar como ID no Firestore.
  /// Remove acentos e substitui espaços por underline.
  static String normalizeId(String text) {
    const withAccents    = 'àáâãäåòóôõöøèéêëìíîïùúûüÿñçÀÁÂÃÄÅÒÓÔÕÖØÈÉÊËÌÍÎÏÙÚÛÜÑÇ';
    const withoutAccents = 'aaaaaaooooooeeeeiiiiuuuuyncAAAAAAOOOOOOEEEEIIIIUUUUNC';

    var result = text.trim();
    for (var i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result.replaceAll(' ', '_');
  }

  /// Busca os dados do estádio no Firestore.
  /// Retorna um Map vazio (nunca null) caso o documento não exista.
  static Future<Map<String, dynamic>> fetchStadium(String localName) async {
    final id = normalizeId(localName);
    debugPrint('🏟️ Buscando estádio com ID: $id');

    final doc = await _firestore.collection(_K.colEstadios).doc(id).get();
    return doc.exists ? (doc.data() ?? {}) : {};
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ═══════════════════════════════════════════════════════════════════

class GameDetailsTab extends StatefulWidget {
  final Game game;

  const GameDetailsTab({super.key, required this.game});

  @override
  State<GameDetailsTab> createState() => _GameDetailsTabState();
}

class _GameDetailsTabState extends State<GameDetailsTab> {
  // ── AdMob ────────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool      _isBannerLoaded = false;

  // ── Dados do estádio (cache local — evita rebuscar a cada rebuild) ─
  late final Future<Map<String, dynamic>> _stadiumFuture;

  // ── Ciclo de vida ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _stadiumFuture = _StadiumService.fetchStadium(widget.game.local);
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // ── AdMob ────────────────────────────────────────────────────────

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _K.adUnitId,
      request:  const AdRequest(),
      size:     AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('⚠️ Banner falhou: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _stadiumFuture,
      builder: (context, snapshot) {
        // ── Loading ───────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        // ── Erro ──────────────────────────────────────────────────
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Não foi possível carregar os dados do estádio.',
            onRetry: () => setState(() {}),
          );
        }

        final data = snapshot.data ?? {};

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF121212) : Colors.grey[50],
          body: RefreshIndicator(
            color: Colors.red,
            onRefresh: () async {
              // Força rebuild para buscar dados novamente
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header com foto do estádio ─────────────────
                  _StadiumHeader(
                    stadiumName: widget.game.local,
                    fotoUrl:     data['fotoUrl'] as String?,
                    isDark:      isDark,
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Últimos confrontos ─────────────────────
                        _SectionTitle(
                          title:  'Últimos Confrontos no Estádio',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _H2HList(
                          historico: List<Map<String, dynamic>>.from(
                              data['ultimosConfrontos'] ?? []),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 28),

                        // ── Desempenho ─────────────────────────────
                        _SectionTitle(
                          title:  'Desempenho no ${widget.game.local}',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _StadiumStats(data: data, isDark: isDark),

                        const SizedBox(height: 28),

                        // ── Curiosidade ────────────────────────────
                        _SectionTitle(
                          title:  'Você sabia?',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _CuriosityCard(
                          text:   data['curiosidades'] as String?,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Banner AdMob fixo na base ────────────────────────────
          bottomNavigationBar: _isBannerLoaded && _bannerAd != null
              ? _BannerAdContainer(ad: _bannerAd!, isDark: isDark)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SUB-WIDGETS — cada um com responsabilidade única
// ═══════════════════════════════════════════════════════════════════

// ── Header ───────────────────────────────────────────────────────

class _StadiumHeader extends StatelessWidget {
  final String  stadiumName;
  final String? fotoUrl;
  final bool    isDark;

  const _StadiumHeader({
    required this.stadiumName,
    required this.fotoUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (fotoUrl != null && fotoUrl!.isNotEmpty)
        ? fotoUrl!
        : _K.fallbackStadiumImg;

    return Stack(
      children: [
        // Foto do estádio
        SizedBox(
          height: 230,
          width:  double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color:  Colors.grey[850],
              child: const Icon(
                Icons.stadium_rounded,
                color: Colors.white38,
                size:  64,
              ),
            ),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white54, strokeWidth: 2),
                    ),
                  ),
          ),
        ),

        // Gradiente sobre a foto
        Container(
          height: 230,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops:  [0.4, 1.0],
            ),
          ),
        ),

        // Nome do estádio
        Positioned(
          bottom: 16,
          left:   16,
          right:  16,
          child: Text(
            stadiumName,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 8, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Últimos confrontos (carrossel horizontal) ─────────────────────

class _H2HList extends StatelessWidget {
  final List<Map<String, dynamic>> historico;
  final bool isDark;

  const _H2HList({required this.historico, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (historico.isEmpty) {
      return _EmptyState(
        icon:    Icons.history_rounded,
        message: 'Sem histórico recente neste estádio.',
        isDark:  isDark,
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:       historico.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final h    = historico[i];
          final tipo = h['tipo'] as String? ?? '-';
          final cor  = _corPorTipo(tipo);

          return Container(
            width: 86,
            decoration: BoxDecoration(
              color:        cor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(color: cor.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tipo,
                  style: TextStyle(
                    color:      cor,
                    fontWeight: FontWeight.bold,
                    fontSize:   22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  h['placar'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _corPorTipo(String tipo) => switch (tipo.toUpperCase()) {
        'V' => Colors.green,
        'E' => Colors.orange,
        _   => Colors.red,
      };
}

// ── Estatísticas do estádio ───────────────────────────────────────

class _StadiumStats extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _StadiumStats({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final v     = _parseInt(data['vitoriasFla']);
    final e     = _parseInt(data['empatesFla']);
    final d     = _parseInt(data['derrotasFla']);
    final total = v + e + d;

    String perc(int val) =>
        total == 0 ? '0%' : '${((val / total) * 100).toStringAsFixed(0)}%';

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color:        cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset:     const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _StatRow(
              label: 'Vitórias',
              value: '$v (${perc(v)})',
              color: Colors.green,
              isDark: isDark,
            ),
            _StatRow(
              label: 'Empates',
              value: '$e (${perc(e)})',
              color: Colors.orange,
              isDark: isDark,
            ),
            _StatRow(
              label: 'Derrotas',
              value: '$d (${perc(d)})',
              color: Colors.red,
              isDark: isDark,
            ),

            // Barra visual de aproveitamento
            const SizedBox(height: 16),
            _AproveitamentoBar(v: v, e: e, d: d, total: total),

            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: Colors.amber[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Artilheiro: ${data['artilheiro'] ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final bool   isDark;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:      color,
              fontWeight: FontWeight.bold,
              fontSize:   14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra colorida mostrando visualmente V/E/D
class _AproveitamentoBar extends StatelessWidget {
  final int v, e, d, total;

  const _AproveitamentoBar({
    required this.v,
    required this.e,
    required this.d,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Flexible(flex: v, child: ColoredBox(color: Colors.green)),
            Flexible(flex: e, child: ColoredBox(color: Colors.orange)),
            Flexible(flex: d, child: ColoredBox(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

// ── Card de curiosidade ───────────────────────────────────────────

class _CuriosityCard extends StatelessWidget {
  final String? text;
  final bool    isDark;

  const _CuriosityCard({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasContent = text != null && text!.isNotEmpty;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        isDark
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(
          color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.red[isDark ? 300 : 700],
            size:  20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasContent ? text! : 'Nenhuma curiosidade disponível.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize:  14,
                height:    1.55,
                color:     isDark
                    ? (hasContent ? Colors.white70 : Colors.white38)
                    : (hasContent ? Colors.black87 : Colors.black38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Títulos de seção ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool   isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  4,
          height: 20,
          decoration: BoxDecoration(
            color:        Colors.red,
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

// ── Estado vazio ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  final bool     isDark;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.symmetric(vertical: 24),
      alignment:   Alignment.center,
      child: Column(
        children: [
          Icon(icon,
              size:  40,
              color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color:   isDark ? Colors.white38 : Colors.black38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado de erro com botão retry ───────────────────────────────

class _ErrorState extends StatelessWidget {
  final String    message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Container do banner AdMob ─────────────────────────────────────

class _BannerAdContainer extends StatelessWidget {
  final BannerAd ad;
  final bool     isDark;

  const _BannerAdContainer({required this.ad, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:     ad.size.width.toDouble(),
      height:    ad.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: AdWidget(ad: ad),
    );
  }
}