import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  /// Retorna um stream de produtos em tempo real.
  /// Pode filtrar por código da loja, se informado.
  static Stream<List<Product>> streamProdutos({String? Loja}) {
    Query query = FirebaseFirestore.instance.collection('produtos');

    if (Loja != null && Loja.isNotEmpty) {
      query = query.where('Loja', isEqualTo: Loja);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
    );
  }

  /// Busca uma lista de produtos de forma única (não em tempo real).
  /// Pode filtrar por código da loja.
  static Future<List<Product>> fetchProdutos({String? Loja}) async {
    final firestore = FirebaseFirestore.instance;

    try {
      Query query = firestore.collection('produtos');

      if (Loja != null && Loja.isNotEmpty) {
        query = query.where('loja', isEqualTo: Loja);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(
          nome: data['nome'] ?? '',
          url: data['url'] ?? '',
          imagem: data['imagem'] ?? '',
          categoria: data['categoria'] ?? 'Outros',
          genero: data['genero'] ?? 'Unissex',
          tipo: data['tipo'] ?? 'Adulto',
          tag: data['promocao'] ?? '',
          preco:
              data['preco'] is String
                  ? double.tryParse(data['preco']) ?? 0.0
                  : (data['preco'] as num?)?.toDouble() ?? 0.0,
          precoPromocional:
              data['precoPromocao'] is String
                  ? double.tryParse(data['precoPromocao']) ?? 0.0
                  : (data['precoPromocao'] as num?)?.toDouble() ?? 0.0,
          loja: data['loja'] ?? '',
          codigoLoja: data['codigoLoja'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      return [];
    }
  }
}
