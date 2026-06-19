import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:pheli_fla_app/screens/loja_screen.dart' as lojaNacao;
import 'package:pheli_fla_app/screens/loja_diversa_screen.dart' as lojaDiversa;

// ─────────────────────────────────────────────
// TEMA DO FLAMENGO — Paleta e Tipografia
// ─────────────────────────────────────────────
abstract class FlaTheme {
  // Cores primárias do Flamengo
  static const Color vermelho = Color(0xFFCC0000);
  static const Color vermelhoVibrante = Color(0xFFE60000);
  static const Color vermelhoEscuro = Color(0xFF8B0000);
  static const Color preto = Color(0xFF0D0D0D);
  static const Color pretoMedio = Color(0xFF1A1A1A);
  static const Color pretoCard = Color(0xFF1E1E1E);
  static const Color ouro = Color(0xFFD4AF37);
  static const Color ouroSuave = Color(0xFFF0C040);
  static const Color branco = Colors.white;

  // Gradiente principal do Flamengo
  static const Gradient gradienteFlamengo = LinearGradient(
    colors: [vermelhoEscuro, vermelho, Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente de fundo dark
  static const Gradient fundoDark = LinearGradient(
    colors: [Color(0xFF0D0D0D), Color(0xFF1C0A0A), Color(0xFF0D0D0D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Gradiente de fundo light
  static const Gradient fundoLight = LinearGradient(
    colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────
// MODELO DE LOJA
// ─────────────────────────────────────────────
class StoreModel {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isSvg;
  final Color themeColor;
  final Widget destination;
  final String heroTag;
  final IconData fallbackIcon;

  const StoreModel({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isSvg,
    required this.themeColor,
    required this.destination,
    required this.heroTag,
    this.fallbackIcon = Icons.store_rounded,
  });
}

// ─────────────────────────────────────────────
// TELA PRINCIPAL
// ─────────────────────────────────────────────
class EscolhaLojaScreen extends StatefulWidget {
  const EscolhaLojaScreen({super.key});

  static const String heroTagNacao = 'hero-loja-nacao';
  static const String heroTagDiversa = 'hero-loja-diversa';
  static const String heroTagBanner = 'hero-banner-shopping-fla';

  @override
  State<EscolhaLojaScreen> createState() => _EscolhaLojaScreenState();
}

class _EscolhaLojaScreenState extends State<EscolhaLojaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Inicia a animação ao montar o widget
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    final List<StoreModel> stores = [
      StoreModel(
        title: 'Loja da Nação',
        subtitle: 'Mantos sagrados, vestuários e acessórios oficiais',
        imagePath: 'assets/images/flamengo_logo.svg',
        isSvg: true,
        themeColor: const Color.fromARGB(255, 246, 244, 244),
        heroTag: EscolhaLojaScreen.heroTagNacao,
        fallbackIcon: Icons.sports_soccer_rounded,
        destination: const lojaNacao.LojaScreen(
          Loja: 'Loja da Nação',
          heroTag: EscolhaLojaScreen.heroTagNacao,
        ),
      ),
      StoreModel(
        title: 'Loja de Produtos Variados',
        subtitle: 'Artigos, presentes e variedades especiais',
        imagePath: 'assets/images/loja_banner.png',
        isSvg: false,
        themeColor: isDark ? FlaTheme.ouro : FlaTheme.pretoMedio,
        heroTag: EscolhaLojaScreen.heroTagDiversa,
        fallbackIcon: Icons.card_giftcard_rounded,
        destination: const lojaDiversa.LojaScreen(
          Loja: 'Loja de Produtos Variados',
          heroTag: EscolhaLojaScreen.heroTagDiversa,
        ),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, isDark, l10n),
        body: Stack(
          children: [
            // Camada de fundo
            _FlaBackground(isDark: isDark),

            // Conteúdo principal com animação de entrada
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainBanner(size, isDark),
                        const SizedBox(height: 28),
                        _buildSectionLabel('NOSSAS LOJAS', isDark),
                        const SizedBox(height: 12),
                        _FlaGlassCard(
                          isDark: isDark,
                          child: Column(
                            children: List.generate(stores.length, (index) {
                              return Column(
                                children: [
                                  _StoreListTile(
                                    store: stores[index],
                                    isDark: isDark,
                                    animationDelay: Duration(
                                      milliseconds: 150 * (index + 1),
                                    ),
                                    parentController: _controller,
                                  ),
                                  if (index < stores.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 72,
                                      color:
                                          isDark
                                              ? Colors.white10
                                              : Colors.black38,
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _ExpandableAboutSection(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: _FlaBackButton(isDark: isDark),
      title: Text(
        l10n.local_escolhaLoja,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: FlaTheme.vermelho,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildMainBanner(Size size, bool isDark) {
    return Hero(
      tag: EscolhaLojaScreen.heroTagBanner,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: size.height * 0.22,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/loja_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Gradiente escuro sobre a imagem
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.black.withOpacity(0.25),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Acento vermelho lateral
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        FlaTheme.vermelhoVibrante,
                        FlaTheme.vermelhoEscuro,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Texto do banner
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge vermelho
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FlaTheme.vermelho,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LOJA PHELIFLA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shopping Fla',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tudo que a Nação precisa em um só lugar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TILE DE LOJA
// ─────────────────────────────────────────────
class _StoreListTile extends StatefulWidget {
  final StoreModel store;
  final bool isDark;
  final Duration animationDelay;
  final AnimationController parentController;

  const _StoreListTile({
    required this.store,
    required this.isDark,
    required this.animationDelay,
    required this.parentController,
  });

  @override
  State<_StoreListTile> createState() => _StoreListTileState();
}

class _StoreListTileState extends State<_StoreListTile> {
  bool _isPressed = false;

  void _onTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget.store.destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _onTap(context);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? (widget.isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              // Ícone da loja
              _StoreIcon(store: widget.store, isDark: widget.isDark),
              const SizedBox(width: 16),

              // Títulos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.store.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.store.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            widget.isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Seta
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.store.themeColor.withOpacity(
                    widget.isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: widget.store.themeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ÍCONE DA LOJA
// ─────────────────────────────────────────────
class _StoreIcon extends StatelessWidget {
  final StoreModel store;
  final bool isDark;

  const _StoreIcon({required this.store, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            store.themeColor.withOpacity(isDark ? 0.25 : 0.12),
            store.themeColor.withOpacity(isDark ? 0.10 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: store.themeColor.withOpacity(isDark ? 0.35 : 0.20),
          width: 1.2,
        ),
      ),
      child:
          store.isSvg
              ? SvgPicture.asset(
                store.imagePath,
                colorFilter: ColorFilter.mode(
                  store.themeColor,
                  BlendMode.srcIn,
                ),
              )
              : ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(store.imagePath, fit: BoxFit.contain),
              ),
    );
  }
}

// ─────────────────────────────────────────────
// SEÇÃO EXPANSÍVEL "CONHEÇA NOSSAS LOJAS"
// ─────────────────────────────────────────────
class _ExpandableAboutSection extends StatefulWidget {
  const _ExpandableAboutSection();

  @override
  State<_ExpandableAboutSection> createState() =>
      _ExpandableAboutSectionState();
}

class _ExpandableAboutSectionState extends State<_ExpandableAboutSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _iconController.forward() : _iconController.reverse();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? FlaTheme.vermelho.withOpacity(0.07)
                : FlaTheme.vermelho.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlaTheme.vermelho.withOpacity(isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(16),
          splashColor: FlaTheme.vermelho.withOpacity(0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: FlaTheme.vermelho.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: FlaTheme.vermelho,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'CONHEÇA NOSSAS LOJAS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        fontSize: 12,
                        color: FlaTheme.vermelho,
                      ),
                    ),
                    const Spacer(),
                    RotationTransition(
                      turns: Tween<double>(
                        begin: 0,
                        end: 0.5,
                      ).animate(_iconController),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: FlaTheme.vermelho,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                // Conteúdo expansível
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child:
                      _isExpanded
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              Divider(
                                color: FlaTheme.vermelho.withOpacity(0.25),
                                height: 1,
                              ),
                              const SizedBox(height: 14),
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13.5,
                                    height: 1.65,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Encontre tudo o que você procura no nosso catálogo selecionado! Acesse a ',
                                    ),
                                    TextSpan(
                                      text: 'Loja da Nação',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? FlaTheme.vermelhoVibrante
                                                : FlaTheme.vermelho,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' para conferir mantos sagrados, vestuários e acessórios oficiais do Mengão. Se procura utilidades, presentes e variedades do dia a dia, explore a ',
                                    ),
                                    TextSpan(
                                      text: 'Loja de Produtos Variados',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' e descubra oportunidades imperdíveis. ',
                                    ),
                                    TextSpan(
                                      text: 'Urubuzada unida! 🦅',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color:
                                            isDark
                                                ? FlaTheme.ouroSuave
                                                : FlaTheme.ouro,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CARD DE VIDRO (GLASSMORPHISM)
// ─────────────────────────────────────────────
class _FlaGlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _FlaGlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withOpacity(0.045)
                    : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FUNDO ANIMADO COM TEMA DO FLAMENGO
// ─────────────────────────────────────────────
class _FlaBackground extends StatelessWidget {
  final bool isDark;
  const _FlaBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente base
        Container(
          decoration: BoxDecoration(
            gradient: isDark ? FlaTheme.fundoDark : FlaTheme.fundoLight,
          ),
        ),

        // Círculo decorativo vermelho superior-esquerdo (sotaque visual)
        if (isDark)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FlaTheme.vermelho.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // Círculo decorativo inferior-direito
        if (isDark)
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FlaTheme.vermelhoEscuro.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// BOTÃO DE VOLTAR CUSTOMIZADO
// ─────────────────────────────────────────────
class _FlaBackButton extends StatelessWidget {
  final bool isDark;
  const _FlaBackButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black38,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
