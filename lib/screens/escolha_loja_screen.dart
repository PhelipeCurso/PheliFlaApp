// screens/escolha_loja_screen.dart
import 'package:flutter/material.dart';
import 'package:pheli_fla_app/screens/loja_screen.dart' as lojaNacao;
import 'package:pheli_fla_app/screens/loja_diversa_screen.dart' as lojaDiversa;

class EscolhaLojaScreen extends StatelessWidget {
  const EscolhaLojaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha sua Loja'),
        backgroundColor: Colors.red[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.store),
              label: const Text('Loja da Nação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            const lojaNacao.LojaScreen(Loja: 'Loja da Nação'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Produtos Variados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => const lojaDiversa.LojaScreen(
                          Loja: 'Produtos Variados',
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
