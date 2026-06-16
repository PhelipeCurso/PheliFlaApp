import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Importação do SDK
import 'package:pheli_fla_app/widgets/competition_list_widget.dart'; // O novo widget genérico

class AgendaRubroNegraPage extends StatefulWidget {
  @override
  _AgendaRubroNegraPageState createState() => _AgendaRubroNegraPageState();
}

class _AgendaRubroNegraPageState extends State<AgendaRubroNegraPage> {
  int _selectedIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // ID de teste oficial do Google para desenvolvimento seguro
  final String _adUnitId = 'ca-app-pub-6735946824045123/9886135824';

  // Lista simplificada usando o widget genérico com os filtros exatos
  final List<Widget> _pages = [
    CompetitionListWidget(competicao: 'brasileirao'),
    CompetitionListWidget(competicao: 'libertadores'),
    CompetitionListWidget(competicao: 'copa do brasil'),
    CompetitionListWidget(competicao: 'super mundial'),
  ];

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  /// Inicializa e carrega o anúncio de banner
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
          debugPrint('Falha ao carregar o banner da Agenda: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Evita memory leak limpando o anúncio ao sair da página
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Rubro-Negra'),
        backgroundColor: Colors.red[800],
        elevation: 0,
      ),
      // Colocamos o IndexedStack e o Banner em uma Column para o banner fixar embaixo
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          // Se o banner carregou, ele aparece aqui, flutuando logo acima da BottomNavigationBar
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[800],
        unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,      
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.trophy),
            label: 'Brasileirão',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.globeAmericas),
            label: 'Libertadores',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shieldAlt),
            label: 'Copa do Brasil',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.medal),
            label: 'Mundial',
          ),
        ],
      ),
    );
  }
}