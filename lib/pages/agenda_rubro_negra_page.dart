import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pheli_fla_app/widgets/competition_list_widget.dart';
import 'package:pheli_fla_app/services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:pheli_fla_app/providers/user_plus_provider.dart';

// ═══════════════════════════════════════════════════════════════════
// CONSTANTES
// ═══════════════════════════════════════════════════════════════════

abstract class _K {
  // ⚠️  Substitua pelo ID real antes de publicar na loja
  static const String adUnitId = 'ca-app-pub-6735946824045123/9886135824';

  // Cores da identidade Flamengo
  static const Color vermelho = Color(0xFFCC0000);
  static const Color preto = Color(0xFF111111);

  // Gradiente do AppBar
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF990000), Color(0xFFCC0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ═══════════════════════════════════════════════════════════════════
// MODEL — aba de competição
// ═══════════════════════════════════════════════════════════════════

class _CompetitionTab {
  final String label;
  final IconData icon;
  final String competicao;

  const _CompetitionTab({
    required this.label,
    required this.icon,
    required this.competicao,
  });
}

// ═══════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════

class AgendaRubroNegraPage extends StatefulWidget {
  const AgendaRubroNegraPage({super.key});

  @override
  State<AgendaRubroNegraPage> createState() => _AgendaRubroNegraPageState();
}

class _AgendaRubroNegraPageState extends State<AgendaRubroNegraPage>
    with SingleTickerProviderStateMixin {
  // ── Abas ─────────────────────────────────────────────────────────
  static const List<_CompetitionTab> _tabs = [
    _CompetitionTab(
      label: 'Brasileirão',
      icon: FontAwesomeIcons.trophy,
      competicao: 'brasileirao',
    ),
    _CompetitionTab(
      label: 'Libertadores',
      icon: FontAwesomeIcons.globeAmericas,
      competicao: 'libertadores',
    ),
    _CompetitionTab(
      label: 'Copa do Brasil',
      icon: FontAwesomeIcons.shieldHalved,
      competicao: 'copa do brasil',
    ),
    _CompetitionTab(
      label: 'Mundial',
      icon: FontAwesomeIcons.medal,
      competicao: 'super mundial',
    ),
  ];

  // Páginas instanciadas uma única vez — IndexedStack as mantém vivas
  static final List<Widget> _pages =
      _tabs
          .map((t) => CompetitionListWidget(competicao: t.competicao))
          .toList();

  // ── State ─────────────────────────────────────────────────────────
  late final TabController _tabController;
  int _selectedIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // ── Ciclo de vida ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _selectedIndex = _tabController.index);
        }
      });
    _loadBanner();
    // Inicializa e carrega interstitial para exibir ao abrir a página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.initialize().then((_) {
        if (mounted) {
          final isPlusUser =
              Provider.of<UserPlusProvider>(context, listen: false).isPremium;
          AdService.instance.loadInterstitial(
            showOnLoad: true,
            isPlusUser: isPlusUser,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    AdService.instance.disposeInterstitial();
    super.dispose();
  }

  // ── AdMob ─────────────────────────────────────────────────────────

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _K.adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
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

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ícones da status bar ficam brancos sobre o header vermelho
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? _K.preto : Colors.grey[50],

        // ── AppBar com gradiente ────────────────────────────────────
        appBar: _buildAppBar(),

        // ── Body: conteúdo + banner AdMob ──────────────────────────
        body: Column(
          children: [
            // Barra de abas visual (abaixo do AppBar)
            _buildTabBar(isDark),

            // Conteúdo das abas — IndexedStack preserva estado ao trocar
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),

            // Banner AdMob — só aparece quando carregado
            if (_isBannerLoaded && _bannerAd != null)
              _BannerAdContainer(ad: _bannerAd!, isDark: isDark),
          ],
        ),
      ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(gradient: _K.headerGradient),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Sombra suave abaixo do header
          shadowColor: Colors.black38,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              const Icon(
                FontAwesomeIcons.shirtsinbulk,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Agenda Rubro-Negra',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Badge com total de competições
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${_tabs.length} competições',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de abas horizontal com scroll
  Widget _buildTabBar(bool isDark) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor =
        isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _K.vermelho,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _K.vermelho,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        onTap: (i) => setState(() => _selectedIndex = i),
        tabs:
            _tabs
                .map(
                  (t) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(t.icon, size: 13),
                          const SizedBox(width: 7),
                          Text(t.label),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BANNER AD CONTAINER
// ═══════════════════════════════════════════════════════════════════

class _BannerAdContainer extends StatelessWidget {
  final BannerAd ad;
  final bool isDark;

  const _BannerAdContainer({required this.ad, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: AdWidget(ad: ad),
    );
  }
}
