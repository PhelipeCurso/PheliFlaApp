import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pheli_fla_app/widgets/competition_list_widget.dart'; // O novo widget genérico

class AgendaRubroNegraPage extends StatefulWidget {
  @override
  _AgendaRubroNegraPageState createState() => _AgendaRubroNegraPageState();
}

class _AgendaRubroNegraPageState extends State<AgendaRubroNegraPage> {
  int _selectedIndex = 0;

  // Lista simplificada usando o widget genérico com os filtros exatos
  final List<Widget> _pages = [
    CompetitionListWidget(competicao: 'brasileirao'),
    CompetitionListWidget(competicao: 'libertadores'),
    CompetitionListWidget(competicao: 'copa do brasil'),
    CompetitionListWidget(competicao: 'super mundial'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Rubro-Negra'),
        backgroundColor: Colors.red[800],
        elevation: 0,
      ),
      body: IndexedStack( // IndexedStack mantém o estado das abas ao alternar
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red[800],
       // MUDANÇA: Garante que o não selecionado mude conforme o tema
      unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
        ? Colors.white54 
        : Colors.grey[600],
     backgroundColor: Theme.of(context).brightness == Brightness.dark 
      ? Color(0xFF1E1E1E) // Cor de fundo para modo escuro
      : Colors.white,      // Cor de fundo para modo claro
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