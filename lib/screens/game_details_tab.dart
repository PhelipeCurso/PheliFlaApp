import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Importação do SDK
import '../models/game.dart';

class GameDetailsTab extends StatefulWidget {
  final Game game;

  const GameDetailsTab({Key? key, required this.game}) : super(key: key);

  @override
  State<GameDetailsTab> createState() => _GameDetailsTabState();
}

class _GameDetailsTabState extends State<GameDetailsTab> {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // IMPORTANTE: ID de teste oficial do Google para Banners.
  // Substitua pelo seu ID real gerado no AdMob apenas quando subir para a loja.
  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  /// Inicializa e carrega o anúncio
  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Falha ao carregar o banner: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Destrói o anúncio ao sair da tela para liberar memória
    super.dispose();
  }

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
    String stadiumId = _normalizeStadiumId(widget.game.local);
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        Map<String, dynamic> stadiumData = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          stadiumData = snapshot.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          backgroundColor: Colors.white, 
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildStadiumHeader(context, stadiumData['fotoUrl']),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Últimos Confrontos no Estádio"),
                      _buildH2HList(false, stadiumData['ultimosConfrontos'] ?? []), 

                      const SizedBox(height: 24),

                      _buildSectionTitle("Desempenho no ${widget.game.local}"),
                      _buildStadiumStats(false, stadiumData), 

                      const SizedBox(height: 24),

                      _buildSectionTitle("Você sabia?"),
                      _buildCuriosityCard(false, stadiumData['curiosidades']), 
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Adiciona o Banner fixado na base da aba caso tenha sido carregado com sucesso
          bottomNavigationBar: _isBannerLoaded && _bannerAd != null
              ? Container(
                  color: Colors.white,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  alignment: Alignment.center,
                  child: AdWidget(ad: _bannerAd!),
                )
              : const SizedBox.shrink(),
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
            widget.game.local,
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
      width: double.infinity, 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.red.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(
        text ?? "Nenhuma curiosidade disponível.",
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 14, 
          color: isDark ? Colors.white70 : Colors.black87, 
          decoration: TextDecoration.none, 
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}