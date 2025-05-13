import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:xml/xml.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pheli_fla_app/config_screenTheme.dart';
import 'package:pheli_fla_app/services/rss_service.dart';
import 'package:pheli_fla_app/pages/noticias_page_coluna.dart';
import 'ge_news.dart';
import 'PheliFla_youtube.dart';
import 'package:pheli_fla_app/widgets/news_card.dart';
import 'package:pheli_fla_app/pages/agenda_rubro_negra_page.dart';

class HomeScreen extends StatefulWidget {
  final String nomeUsuario;
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;

  const HomeScreen({
    Key? key,
    required this.nomeUsuario,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isDarkMode;
  int _selectedIndex = 0;
  late Future<List<Map<String, String>>> noticiasGE;
  late Future<List<Map<String, String>>> noticiasColuna;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    noticiasGE = _buscarNoticiasGE();
    noticiasColuna = fetchColunaFlaRSS();
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
    widget.onThemeChanged(value);
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<List<Map<String, String>>> _buscarNoticiasGE() async {
    try {
      final response = await http.get(
        Uri.parse('https://ge.globo.com/futebol/times/flamengo/'),
      );
      if (response.statusCode == 200) {
        final document = htmlParser.parse(response.body);
        final elements = document.querySelectorAll('.feed-post-body');
        return elements.take(10).map((element) {
          final titulo =
              element.querySelector('.feed-post-link')?.text.trim() ??
              'Sem título';
          final link =
              element.querySelector('.feed-post-link')?.attributes['href'] ??
              '';
          final img = element.querySelector('img')?.attributes['src'] ?? '';
          return {
            'titulo': titulo,
            'link': link.startsWith('http') ? link : 'https:$link',
            'imagem': img,
          };
        }).toList();
      } else {
        throw Exception('Falha ao carregar notícias GE');
      }
    } catch (e) {
      print('Erro ao buscar notícias GE: $e');
      return [];
    }
  }

  /* Future<List<Map<String, String>>> _buscarNoticiasColunaDoFla() async {
    try {
      final response = await http.get(
        Uri.parse('https://colunadofla.com/feed/'),
      );
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        return items.map((item) {
          final titulo = item.getElement('title')?.text ?? 'Sem título';
          final link = item.getElement('link')?.text ?? '';
          final descricaoBruta = item.getElement('description')?.text ?? '';
          final imagem = extrairImagem(descricaoBruta) ?? '';
          final descricaoSemHtml =
              htmlParser.parse(descricaoBruta).body?.text ?? '';
          return {
            'titulo': titulo,
            'link': link,
            'descricao': descricaoSemHtml,
            'imagem': imagem,
          };
        }).toList();
      } else {
        throw Exception('Erro ao buscar feed RSS do Coluna do Fla');
      }
    } catch (e) {
      print('Erro ao buscar notícias Coluna do Fla: $e');
      return [];
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? photoURL = user?.photoURL;

    final tabs = [
      _buildNoticiasGE(),
      NoticiasPage(noticiascoluna: noticiasColuna),
      const PheliFlaYoutube(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? AppLocalizations.of(context)!.newsGeTitle
              : _selectedIndex == 1
              ? AppLocalizations.of(context)!.colunaTitle
              : AppLocalizations.of(context)!.youtubeTitle,
        ),
        backgroundColor: Colors.red[800],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red[800]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        photoURL != null
                            ? NetworkImage(photoURL)
                            : const AssetImage('assets/images/Gaming.png')
                                as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Olá, ${widget.nomeUsuario}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context)!.home),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(AppLocalizations.of(context)!.chat),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/room-selection',
                  arguments: widget.nomeUsuario,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_soccer),
              title: Text(AppLocalizations.of(context)!.agendaTitle),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Em desenvolvimento'),
                        content: const Text(
                          'Este recurso está em desenvolvimento. Em breve estará disponível!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text(AppLocalizations.of(context)!.store),
              onTap: () => Navigator.pushNamed(context, '/loja'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SettingsScreen(
                          isDarkMode: isDarkMode,
                          onThemeChanged: toggleTheme,
                        ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context)!.logout),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[800],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: AppLocalizations.of(context)!.bottomNavGe,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chrome_reader_mode),
            label: AppLocalizations.of(context)!.bottomNavColuna,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection),
            label: AppLocalizations.of(context)!.bottomNavYoutube,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiasGE() {
    return FutureBuilder<List<Map<String, String>>>(
      future: noticiasGE,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar notícias: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sem notícias disponíveis.'));
        } else {
          return ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            children:
                snapshot.data!.map((noticia) {
                  return NewsCard(
                    titulo: noticia['titulo']!,
                    imagem: noticia['imagem']!,
                    link: noticia['link']!,
                  );
                }).toList(),
          );
        }
      },
    );
  }

  Widget _noticiaItem({
    required String titulo,
    required String imagem,
    required String link,
  }) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem.isNotEmpty)
              Image.network(
                imagem,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
