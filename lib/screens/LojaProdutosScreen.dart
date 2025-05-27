import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LojaProdutosScreen extends StatelessWidget {
  final String nomeLoja;

  const LojaProdutosScreen({super.key, required this.nomeLoja});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nomeLoja),
        backgroundColor: Colors.red[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('produtos')
            .where('loja', isEqualTo: nomeLoja)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum produto encontrado."));
          }

          final produtos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Image.network(produto['imagem'], width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(produto['nome']),
                  subtitle: Text("R\$ ${produto['preco'].toString()}"),
                  onTap: () {
                    // Aqui você pode adicionar detalhes do produto
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
