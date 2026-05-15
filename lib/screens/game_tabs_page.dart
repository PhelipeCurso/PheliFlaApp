import 'package:flutter/material.dart';
import 'package:pheli_fla_app/models/game.dart';
import 'package:pheli_fla_app/screens/confrontos_tab.dart';
import 'package:pheli_fla_app/screens/game_details_tab.dart';

class GameTabsPage extends StatelessWidget {
  final Game game;

  const GameTabsPage({Key? key, required this.game}) : super(key: key);

@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: Colors.white, // FORÇANDO O FUNDO BRANCO AQUI
      appBar: AppBar(
        title: const Text("Detalhes da Partida"),
        backgroundColor: Colors.red[900],
        elevation: 0,
        bottom: const TabBar(
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "CONFRONTOS", icon: Icon(Icons.shield)),
            Tab(text: "ESTÁDIO", icon: Icon(Icons.stadium)),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          ConfrontosTab(game: game),
          GameDetailsTab(game: game), 
        ],
      ),
    ),
  );
}
}