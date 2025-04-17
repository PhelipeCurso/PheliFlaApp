import '../models/product.dart';

Future<List<Product>> fetchProdutos() async {
  // Simulando um delay como se fosse da API
  await Future.delayed(const Duration(seconds: 1));

  // Mock de produtos
  return [
    Product(
      nome: 'Camisa Origens 1895 Licenciada Flamengo',
      url: 'https://s.shopee.com.br/1qOmfv2mrL',
      imagem:
          'https://down-br.img.susercontent.com/file/sg-11134201-7renm-m8afcp88r5b681.webp',
    ),
    Product(
      nome: 'Manto Flamengo Jogo 1 Fan adidas 2025',
      url: 'https://mercadolivre.com/sec/21u2ydB',
      imagem:
          'https://down-br.img.susercontent.com/file/br-11134207-7r98o-m6svs4sl2a133a.webp',
    ),
    Product(
      nome: 'CANECA GEL 300ML - FLAMENGO LIBERTADORES PRETA',
      url: 'https://s.shopee.com.br/9f7e0i2rvp',
      imagem:
          'https://down-br.img.susercontent.com/file/br-11134207-7qukw-li96kpcfmxdr01.webp',
    ),
  ];
}
