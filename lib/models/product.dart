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
  final String plataforma;
  final bool entregaFull;

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
    required this.plataforma,
    this.entregaFull = false,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Tratamento seguro para o preço base
    double? precoFinal;
    if (data['preco'] != null) {
      precoFinal = data['preco'] is String
          ? double.tryParse(data['preco'])
          : (data['preco'] as num?)?.toDouble();
    }

    // Tratamento seguro para o preço promocional
    double? precoPromocionalFinal;
    if (data['precoPromocional'] != null) {
      precoPromocionalFinal = data['precoPromocional'] is String
          ? double.tryParse(data['precoPromocional'])
          : (data['precoPromocional'] as num?)?.toDouble();
    }
   
    // ✅ CORREÇÃO DEFINITIVA: Converte String ou Bool com segurança e evita nulos
    bool entregaFullSegura = false;
    if (data['entregaFull'] != null) {
      if (data['entregaFull'] is bool) {
        entregaFullSegura = data['entregaFull'] as bool;
      } else {
        entregaFullSegura = data['entregaFull'].toString().toLowerCase() == 'true';
      }
    }

    return Product(
      nome: data['nome'] ?? '',
      url: data['url'] ?? '',
      imagem: data['imagem'] ?? '',
      categoria: data['categoria'] ?? 'Outros',
      genero: data['genero'] ?? 'Unissex',
      tipo: data['tipo'] ?? 'Adulto',
      tag: data['promocao'] ?? '',
      preco: precoFinal ?? 0.0,
      precoPromocional: precoPromocionalFinal ?? 0.0,
      loja: data['loja'] ?? '',
      codigoLoja: data['codigoLoja'] ?? data['codigo'] ?? '',
      plataforma: data['plataforma'] ?? '',
      entregaFull: entregaFullSegura, // ✅ Injetado com segurança
    );
  }
}