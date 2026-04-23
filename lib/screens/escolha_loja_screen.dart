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

    // Lista de lojas para facilitar a manutenção
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
        imagePath: 'assets/images/loja_banner.png', // Ajustado para asset correto
        isSvg: false,
        themeColor: Colors.blueGrey.shade700,
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
        title: Text(l10n.local_escolhaLoja, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) => _StoreRow(store: stores[index]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAboutButton(),
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
          color: Colors.black26,
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
            ? [Colors.black, Colors.grey.shade900] 
            : [Colors.white, Colors.grey.shade100],
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
        height: size.height * 0.22,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/loja_banner.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Shopping Fla', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Tudo o que você precisa em um só lugar', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.info_outline, size: 18),
        label: const Text("CONHEÇA NOSSAS LOJAS"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      leading: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: store.themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: store.isSvg
            ? SvgPicture.asset(store.imagePath)
            : Image.asset(store.imagePath, fit: BoxFit.contain),
      ),
      title: Text(store.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(store.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(Icons.chevron_right_rounded),
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.white),
          ),
          child: child,
        ),
      ),
    );
  }
}