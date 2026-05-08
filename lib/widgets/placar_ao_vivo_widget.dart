import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlacarDinamico extends StatelessWidget {
  const PlacarDinamico({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // Escuta o documento que o seu painel React atualiza
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('placar_atual')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Erro ao carregar placar');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink(); // Esconde se não houver jogo ativo
        }

        var dados = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          color: Colors.black, // Estilo Rubro-Negro
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Badge(
                  label: Text(dados['status'] ?? 'Em breve'),
                  backgroundColor: Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  dados['placar'] ?? 'Carregando...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dados['detalhes'] != null && dados['detalhes'] != "")
                  Text(
                    dados['detalhes'],
                    style: const TextStyle(color: Colors.yellow, fontSize: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}