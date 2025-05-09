import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'brasileirao_page.dart';
import 'libertadores_page.dart';
import 'copa_do_brasil_page.dart';
import 'super_mundial_page.dart';

class AgendaRubroNegraPage extends StatefulWidget {
  @override
  _AgendaRubroNegraPageState createState() => _AgendaRubroNegraPageState();
}

class _AgendaRubroNegraPageState extends State<AgendaRubroNegraPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BrasileiraoPage(),
    LibertadoresPage(),
    CopaDoBrasilPage(),
    SuperMundialPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Rubro-Negra'),
        backgroundColor: Colors.red[800],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[800],
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
