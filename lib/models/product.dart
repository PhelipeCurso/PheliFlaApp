import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String nome;
  final String imagem;
  final String url;
  final String categoria;
  final String genero;
  final String tipo;
  final String tag;
  final double? preco;
  final double? precoPromocional;
  final String? loja;
  final String codigoLoja;

  Product({
    required this.nome,
    required this.imagem,
    required this.url,
    required this.categoria,
    required this.genero,
    required this.tipo,
    this.tag = '',
    this.preco,
    this.precoPromocional,
    this.loja,
    required this.codigoLoja,
  });
  factory Product.fromFirestore(DocumentSnapshot doc) {
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
  }
}
