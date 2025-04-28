class Product {
  final String nome;
  final String imagem;
  final String url;
  final String categoria;
  final String genero; // Masculino, Feminino, Unissex
  final String tipo; // Infantil, Adulto
  final String tag;

  Product({
    required this.nome,
    required this.imagem,
    required this.url,
    required this.categoria,
    required this.genero,
    required this.tipo,
    this.tag='',
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
    );
  }
}
