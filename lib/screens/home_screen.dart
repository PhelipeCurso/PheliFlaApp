import 'package:flamengo_chat/config_screenTheme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class HomeScreen extends StatefulWidget {
  final String nomeUsuario;
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;

  const HomeScreen({
    Key? key,
    required this.nomeUsuario,
    required this.isDarkMode,
    required this.onThemeChanged, 
    //required String photoUrl,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isDarkMode;
  List<Map<String, String>> noticias = [];

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _buscarNoticias();
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

  Future<void> _buscarNoticias() async {
    try {
      final response = await http.get(
        Uri.parse('https://ge.globo.com/futebol/times/flamengo/'),
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('.feed-post-body');

        final novasNoticias =
            elements.take(10).map((element) {
              final titulo =
                  element.querySelector('.feed-post-link')?.text.trim() ??
                  'Sem título';
              final link =
                  element
                      .querySelector('.feed-post-link')
                      ?.attributes['href'] ??
                  '';
              final img = element.querySelector('img')?.attributes['src'] ?? '';

              return {
                'titulo': titulo,
                'link': link.startsWith('http') ? link : 'https:$link',
                'imagem': img,
              };
            }).toList();

        setState(() {
          noticias = novasNoticias;
        });
      }
    } catch (e) {
      print('Erro ao buscar notícias: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? photoURL = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PheliFla Notícias'),
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
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Bate-Papo'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/room-selection',
                  arguments: widget.nomeUsuario,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
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
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Loja'),
              onTap: () {
                Navigator.pushNamed(context, '/loja');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Últimas Notícias do Mengão:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...noticias.map(
            (noticia) => _noticiaItem(
              titulo: noticia['titulo']!,
              imagem: noticia['imagem']!,
              link: noticia['link']!,
            ),
          ),
        ],
      ),
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
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                titulo,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
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
