import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

Future<List<Product>> fetchProdutos() async {
  final firestore = FirebaseFirestore.instance;

  try {
    final snapshot = await firestore.collection('produtos').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product(
        nome: data['nome'] ?? '',
        url: data['url'] ?? '',
        imagem: data['imagem'] ?? '',
        categoria: data['categoria'] ?? 'Outros',
        genero: data['genero'] ?? 'Unissex',
        tipo: data['tipo'] ?? 'Adulto',
        tag: data['promocao'] ?? '',
      );
    }).toList();
  } catch (e) {
    print('Erro ao buscar produtos: $e');
    return [];
  }
}
