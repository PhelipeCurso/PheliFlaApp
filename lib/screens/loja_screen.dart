import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({super.key});

  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  late Future<List<Product>> _produtosFuture;

  @override
  void initState() {
    super.initState();
    _produtosFuture = fetchProdutos();
  }

  void _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir o link: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loja Oficial')),
      body: FutureBuilder<List<Product>>(
        future: _produtosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produtos.'));
          }

          final produtos = snapshot.data ?? [];

          return ListView.builder(
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final item = produtos[index];
              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Image.network(item.imagem, width: 50),
                  title: Text(item.nome),
                  trailing: const Icon(Icons.shopping_cart_outlined),
                  onTap: () => _abrirLink(item.url),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
