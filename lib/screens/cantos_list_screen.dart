// lib/screens/cantos_list_screen.dart
import 'package:flutter/material.dart';
import '../services/canto_service.dart';
import '../models/canto_model.dart';
import 'canto_detalhes_screen.dart';

class CantosListScreen extends StatefulWidget {
  const CantosListScreen({super.key});

  @override
  State<CantosListScreen> createState() => _CantosListScreenState();
}

class _CantosListScreenState extends State<CantosListScreen> {
  final CantoService _cantoService = CantoService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cantos e Hinos', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFC52026), // Vermelho do Mengão
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Oficiais'),
              Tab(text: 'Clássicos'),
              Tab(text: 'Recentes'),
            ],
          ),
        ),
        body: StreamBuilder<List<CantoModel>>(
          stream: _cantoService.getCantos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFC52026)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum canto cadastrado ainda.'));
            }

            List<CantoModel> todosOsCantos = snapshot.data!;

            // Filtra as listas por categoria de acordo com o value do select do React
            List<CantoModel> oficiais = todosOsCantos.where((c) => c.categoria == 'oficial').toList();
            List<CantoModel> classicos = todosOsCantos.where((c) => c.categoria == 'arquibancada').toList();
            List<CantoModel> recentes = todosOsCantos.where((c) => c.categoria == 'recentes').toList();

            return TabBarView(
              children: [
                _buildLista(oficiais),
                _buildLista(classicos),
                _buildLista(recentes),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLista(List<CantoModel> cantos) {
    if (cantos.isEmpty) {
      return const Center(child: Text('Nenhuma música nesta categoria.'));
    }
    return ListView.builder(
      itemCount: cantos.length,
      itemBuilder: (context, index) {
        final canto = cantos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.music_note, color: Color(0xFFC52026)),
            title: Text(canto.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CantoDetalhesScreen(canto: canto),
                ),
              );
            },
          ),
        );
      },
    );
  }
}