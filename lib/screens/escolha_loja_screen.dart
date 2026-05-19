import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:pheli_fla_app/screens/loja_screen.dart' as lojaNacao;
import 'package:pheli_fla_app/screens/loja_diversa_screen.dart' as lojaDiversa;

// Modelo simples para organizar as lojas
class StoreModel {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isSvg;
  final Color themeColor;
  final Widget destination;
  final String heroTag;

  StoreModel({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isSvg,
    required this.themeColor,
    required this.destination,
    required this.heroTag,
  });
}

class EscolhaLojaScreen extends StatelessWidget {
  const EscolhaLojaScreen({super.key});

  static const String heroTagNacao = 'hero-loja-nacao';
  static const String heroTagDiversa = 'hero-loja-diversa';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    final List<StoreModel> stores = [
      StoreModel(
        title: 'Loja da Nação',
        subtitle: 'Camisas e acessórios oficiais',
        imagePath: 'assets/images/flamengo_logo.svg',
        isSvg: true,
        themeColor: const Color(0xFFCB1B1B),
        heroTag: heroTagNacao,
        destination: const lojaNacao.LojaScreen(Loja: 'Loja da Nação', heroTag: heroTagNacao),
      ),
      StoreModel(
        title: 'Loja de Produtos Variados',
        subtitle: 'Artigos, presentes e diversos',
        imagePath: 'assets/images/loja_banner.png',
        isSvg: false,
        themeColor: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A),
        heroTag: heroTagDiversa,
        destination: const lojaDiversa.LojaScreen(Loja: 'Loja de Produtos Variados', heroTag: heroTagDiversa),
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(context),
        title: Text(
          l10n.local_escolhaLoja, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildMainBanner(size),
                  const SizedBox(height: 24),
                  
                  _GlassCard(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stores.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1, 
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                      itemBuilder: (context, index) => _StoreRow(store: stores[index]),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botão Expandível que abriga o texto informativo
                  const _ExpandableAboutButton(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: ClipOval(
        child: Container(
          color: Colors.black38,
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF0A0A0A), const Color(0xFF161616)] 
            : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildMainBanner(Size size) {
    return Hero(
      tag: heroTagNacao,
      child: Container(
        height: size.height * 0.24,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/loja_banner.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), 
              blurRadius: 15, 
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.2),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Shopping Fla', 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 26, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tudo o que você precisa em um só lugar', 
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Stateful Customizado para o Botão Expandível
class _ExpandableAboutButton extends StatefulWidget {
  const _ExpandableAboutButton();

  @override
  State<_ExpandableAboutButton> createState() => _ExpandableAboutButtonState();
}

class _ExpandableAboutButtonState extends State<_ExpandableAboutButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryRed = Color(0xFFCB1B1B);
    final baseColor = isDark ? Colors.white70 : Colors.black87;
    final highlightColor = isDark ? const Color(0xFFFF4D4D) : const Color(0xFFCB1B1B);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryRed.withOpacity(isDark ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryRed, width: 1.5),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Linha Principal do Botão (Estilo Outlined)
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: primaryRed),
                  const Spacer(),
                  const Text(
                    "CONHEÇA NOSSAS LOJAS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2,
                      color: primaryRed,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded, 
                      color: primaryRed,
                    ),
                  ),
                ],
              ),
              
              // Seção de Conteúdo Oculto com Animação de Tamanho
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Divider(color: primaryRed.withOpacity(0.3), height: 1),
                          const SizedBox(height: 14),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(color: baseColor, fontSize: 14, height: 1.5),
                              children: [
                                const TextSpan(text: 'Encontre tudo o que procura em nosso catálogo selecionado! Acesse a '),
                                TextSpan(
                                  text: 'Loja da Nação',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: highlightColor),
                                ),
                                const TextSpan(text: ' para conferir mantos sagrados, vestuários e acessórios oficiais do Mengão. Se procura utilidades, presentes e variedades do dia a dia, explore a '),
                                TextSpan(
                                  text: 'Loja de Produtos Variados',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                ),
                                const TextSpan(text: ' e descubra oportunidades imperdíveis.'),
                              ],
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  final StoreModel store;
  const _StoreRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      leading: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: store.themeColor.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: store.themeColor.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: store.isSvg
            ? SvgPicture.asset(
                store.imagePath,
                colorFilter: ColorFilter.mode(
                  store.themeColor == Colors.white ? Colors.white : store.themeColor, 
                  BlendMode.srcIn,
                ),
              )
            : Image.asset(store.imagePath, fit: BoxFit.contain),
      ),
      title: Text(
        store.title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          store.subtitle, 
          style: TextStyle(
            fontSize: 13, 
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => store.destination)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}