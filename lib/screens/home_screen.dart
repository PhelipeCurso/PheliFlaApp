import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pheli_fla_app/constants/app_constants.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';

import 'package:pheli_fla_app/widgets/custom_drawer.dart';
import 'package:pheli_fla_app/services/home_service.dart';
import 'package:pheli_fla_app/services/rss_service.dart';
import 'package:pheli_fla_app/pages/noticias_page_coluna.dart';
import 'PheliFla_youtube.dart';
import 'package:pheli_fla_app/widgets/news_card.dart';
import 'package:pheli_fla_app/widgets/phelifla_card.dart';
import 'package:pheli_fla_app/screens/NoticiaDetalhePage.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final String nomeUsuario;
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;
  final bool isPlusUser;

  const HomeScreen({
    Key? key,
    required this.nomeUsuario,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.isPlusUser,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeService _homeService = HomeService();

  late bool isDarkMode;
  int _selectedIndex = 0;

  late Future<List<Map<String, String>>> noticiasPheliFla;
  late Future<List<Map<String, String>>> noticiasGE;
  late Future<List<Map<String, String>>> noticiasColuna;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    noticiasPheliFla = _homeService.fetchNoticiasPheliFla();
    noticiasGE = _homeService.fetchNoticiasGE();
    noticiasColuna = fetchColunaFlaRSS();
  }

  // --- FUNÇÃO PARA ABRIR O SITE DE INGRESSOS ---
  Future<void> _abrirSiteIngressos() async {
    final Uri url = Uri.parse(
      'https://ingressos.flamengo.com.br/?utm_source=siteoficial&utm_medium=popup&utm_campaign=flaxremo&utm_term=_',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link: $url');
    }
  }

  void toggleTheme(bool value) {
    setState(() => isDarkMode = value);
    widget.onThemeChanged(value);
  }

  void _logout(BuildContext context) async {
    try {
      // 1. Pega o UID do usuário atual
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // 2. Avisa ao Firestore que ele está saindo
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({'isOnline': false});
      }

      // 3. Agora sim, faz o logout do Firebase Auth
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 4. Redireciona para o login limpando a pilha de telas
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      print("Erro ao sair: $e");
      // Mesmo se der erro no update, forçamos o deslogue para não travar o usuário
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      _buildNoticiasPheliFlaView(),
      _buildNoticiasGEView(),
      NoticiasPage(noticiascoluna: noticiasColuna),
      const PheliFlaYoutube(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      drawer: CustomDrawer(
        user: FirebaseAuth.instance.currentUser,
        nomeUsuario: widget.nomeUsuario,
        isDarkMode: isDarkMode,
        onThemeChanged: toggleTheme,
        onLogout: () => _logout(context),
        onTicketsTap: _abrirSiteIngressos,
      ),
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.stars),
            label: "PheliFla",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article),
            label: AppLocalizations.of(context).bottomNavGe,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chrome_reader_mode),
            label: AppLocalizations.of(context).bottomNavColuna,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_collection),
            label: AppLocalizations.of(context).bottomNavYoutube,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "PheliFla News";
      case 1:
        return AppLocalizations.of(context).newsGeTitle;
      case 2:
        return AppLocalizations.of(context).colunaTitle;
      case 3:
        return AppLocalizations.of(context).youtubeTitle;
      default:
        return "PheliFla App";
    }
  }

  Widget _buildNoticiasPheliFlaView() {
    return FutureBuilder<List<Map<String, String>>>(
      future: noticiasPheliFla,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Nenhuma notícia própria postada ainda.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final noticia = snapshot.data![index];
            return PheliFlaCard(
              titulo: noticia['titulo']!,
              imagem: noticia['imagem']!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoticiaDetalhePage(noticia: noticia),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNoticiasGEView() {
    return FutureBuilder<List<Map<String, String>>>(
      future: noticiasGE,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }
        final lista = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final noticia = lista[index];
            return NewsCard(
              titulo: noticia['titulo']!,
              imagem: noticia['imagem']!,
              link: noticia['link']!,
            );
          },
        );
      },
    );
  }
}
