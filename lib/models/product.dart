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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nome: json['nome'],
      imagem: json['imagem'],
      url: json['url'],
      categoria: json['categoria'] ?? '',
      genero: json['genero'] ?? '',
      tipo: json['tipo'] ?? '',
      tag: json['promocao'] ?? '',
      preco: json['preco'] != null ? double.tryParse(json['preco'].toString()) : null,
      precoPromocional: json['precoPromocional'] != null
          ? double.tryParse(json['precoPromocional'].toString())
          : null,
    );
  }
}
