class Product {
  final String nome;
  final String url;
  final String imagem;

  Product({required this.nome, required this.url, required this.imagem});

  // No futuro, quando vier da API (JSON), podemos usar:
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nome: json['nome'],
      url: json['url'],
      imagem: json['imagem'],
    );
  }
}
