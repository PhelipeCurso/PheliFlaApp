import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pheli_fla_app/config_screenTheme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:cached_network_image/cached_network_image.dart';

// Seus imports
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:pheli_fla_app/services/rss_service.dart';
import 'package:pheli_fla_app/pages/noticias_page_coluna.dart';
import 'ge_news.dart';
import 'PheliFla_youtube.dart';
import 'package:pheli_fla_app/widgets/news_card.dart';
import 'package:pheli_fla_app/pages/agenda_rubro_negra_page.dart';
import 'package:pheli_fla_app/screens/escolha_loja_screen.dart';
import 'package:pheli_fla_app/screens/assinatura_plus_screen.dart';
import 'NoticiaDetalhePage.dart';

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
  late bool isDarkMode;
  int _selectedIndex = 0;

  late Future<List<Map<String, String>>> noticiasPheliFla;
  late Future<List<Map<String, String>>> noticiasGE;
  late Future<List<Map<String, String>>> noticiasColuna;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    noticiasPheliFla = _buscarNoticiasPheliFla();
    noticiasGE = _buscarNoticiasGE();
    noticiasColuna = fetchColunaFlaRSS();
  }

  // --- FUNÇÃO PARA ABRIR O SITE DE INGRESSOS ---
  Future<void> _abrirSiteIngressos() async {
    final Uri url = Uri.parse(
        'https://ingressos.flamengo.com.br/?utm_source=siteoficial&utm_medium=popup&utm_campaign=flaxremo&utm_term=_');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Não foi possível abrir o link: $url');
    }
  }

  // --- BUSCA FIRESTORE (SUAS POSTAGENS) ---
  Future<List<Map<String, String>>> _buscarNoticiasPheliFla() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('noticias')
          .orderBy('dataCriacao', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'titulo': data['titulo']?.toString() ?? 'Sem título',
          'link': data['id']?.toString() ?? '',
          'imagem': data['imagemUrl']?.toString() ?? '',
          'conteudo': data['conteudo']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Erro Firestore PheliFla: $e');
      return [];
    }
  }

  // --- BUSCA GE (SCRAPING) ---
  Future<List<Map<String, String>>> _buscarNoticiasGE() async {
    try {
      final response = await http.get(
        Uri.parse('https://ge.globo.com/futebol/times/flamengo/'),
        headers: {"User-Agent": "Mozilla/5.0"},
      );

      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);
        final elements = document.querySelectorAll('.feed-post-body');
        List<Map<String, String>> resultados = [];

        for (var element in elements) {
          final linkElement = element.querySelector('.feed-post-link');
          final link = linkElement?.attributes['href'] ?? '';
          if (link.contains('globo.com')) {
            final titulo = linkElement?.text.trim() ?? 'Sem título';
            final img = element.parent?.querySelector('img')?.attributes['src'] ?? '';
            resultados.add({
              'titulo': titulo,
              'link': link.startsWith('http') ? link : 'https:$link',
              'imagem': img,
            });
          }
          if (resultados.length >= 10) break;
        }
        return resultados;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void toggleTheme(bool value) {
    setState(() => isDarkMode = value);
    widget.onThemeChanged(value);
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
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
        backgroundColor: Colors.red[800],
        elevation: 0,
      ),
      drawer: _buildCustomDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.stars),
            label: "PheliFla",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article),
            label: AppLocalizations.of(context)!.bottomNavGe,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chrome_reader_mode),
            label: AppLocalizations.of(context)!.bottomNavColuna,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.video_collection),
            label: AppLocalizations.of(context)!.bottomNavYoutube,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return "Coluna do PheliFla";
      case 1: return AppLocalizations.of(context)!.newsGeTitle;
      case 2: return AppLocalizations.of(context)!.colunaTitle;
      case 3: return AppLocalizations.of(context)!.youtubeTitle;
      default: return "PheliFla App";
    }
  }

  Widget _buildNoticiasPheliFlaView() {
    return FutureBuilder<List<Map<String, String>>>(
      future: noticiasPheliFla,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma notícia própria postada ainda.'));
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
          return const Center(child: CircularProgressIndicator(color: Colors.red));
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

  // --- DRAWER (MENU LATERAL) ---
  Widget _buildCustomDrawer() {
    final User? user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.red[800]),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const AssetImage('assets/images/Gaming.png') as ImageProvider,
            ),
            accountName: Text(widget.nomeUsuario, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? ""),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(AppLocalizations.of(context)!.home),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: Text(AppLocalizations.of(context)!.chat),
                  onTap: () => Navigator.pushNamed(context, '/room-selection', arguments: widget.nomeUsuario),
                ),
                ListTile(
                  leading: const Icon(Icons.sports_soccer),
                  title: Text(AppLocalizations.of(context)!.agendaTitle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaRubroNegraPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text(AppLocalizations.of(context)!.store),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EscolhaLojaScreen()));
                  },
                ),
                
                // --- ITEM AJUSTADO: INGRESSOS ABAIXO DA LOJA ---
                ListTile(
                  leading: const Icon(Icons.confirmation_number, color: Colors.red),
                  title: const Text('Ingressos'),
                  subtitle: const Text('Compre ingressos para os jogos'),
                  onTap: () {
                    Navigator.pop(context); // Fecha o Drawer
                    _abrirSiteIngressos(); // Abre o site
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Assinar Agora'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AssinaturaPlusScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.settings),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          isDarkMode: isDarkMode,
                          onThemeChanged: toggleTheme,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(AppLocalizations.of(context)!.logout),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- CARD PERSONALIZADO PHELIFLA ---
class PheliFlaCard extends StatelessWidget {
  final String titulo;
  final String imagem;
  final VoidCallback onTap;

  const PheliFlaCard({
    Key? key,
    required this.titulo,
    required this.imagem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imagem,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}