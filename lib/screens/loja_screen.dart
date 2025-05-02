import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  String _categoriaSelecionada = 'Todos';
  String _generoSelecionado = 'Todos';
  String _tipoSelecionado = 'Todos';

  final List<String> categorias = [
    'Todos',
    'Camisas',
    'Bonés',
    'Acessórios',
    'Canecas',
    'Cropped',
    'Body',
    'kit',
  ];
  final List<String> generos = ['Todos', 'Masculino', 'Feminino', 'Unissex'];
  final List<String> tipos = ['Todos', 'Infantil', 'Adulto'];
  //final precoController = TextEditingController();
  //final precoPromocionalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _produtosFuture = fetchProdutos();
  }

  Future<void> _abrirLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _mostrarErro(AppLocalizations.of(context)!.openLinkFail(url));
      }
    } catch (e) {
      _mostrarErro(AppLocalizations.of(context)!.openLinkError(e.toString()));
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<Product> _filtrarProdutos(List<Product> produtos) {
    return produtos.where((p) {
      final categoriaOk =
          _categoriaSelecionada == 'Todos' ||
          p.categoria == _categoriaSelecionada;
      final generoOk =
          _generoSelecionado == 'Todos' || p.genero == _generoSelecionado;
      final tipoOk = _tipoSelecionado == 'Todos' || p.tipo == _tipoSelecionado;
      return categoriaOk && generoOk && tipoOk;
    }).toList();
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.storeTitle),
        backgroundColor: Colors.red[800],
      ),
      body: FutureBuilder<List<Product>>(
        future: _produtosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produtos.'));
          }

          final produtos = _filtrarProdutos(snapshot.data ?? []);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            local.category,
                            categorias,
                            _categoriaSelecionada,
                            (value) =>
                                setState(() => _categoriaSelecionada = value!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdown(
                            local.gender,
                            generos,
                            _generoSelecionado,
                            (value) =>
                                setState(() => _generoSelecionado = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      local.type,
                      tipos,
                      _tipoSelecionado,
                      (value) => setState(() => _tipoSelecionado = value!),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    produtos.isEmpty
                        ? Center(child: Text(local.noProducts))
                        : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                          itemCount: produtos.length,
                          itemBuilder: (context, index) {
                            final item = produtos[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap:
                                    () =>
                                        item.url.isNotEmpty
                                            ? _abrirLink(item.url)
                                            : _mostrarErro(local.invalidUrl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(15),
                                              ),
                                          child: Image.network(
                                            item.imagem,
                                            height: 190,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const SizedBox(
                                                      height: 130,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                        ),
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        if (item.tag.isNotEmpty)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    item.tag == 'Promoção'
                                                        ? Colors.green
                                                        : Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.tag,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if ((item.precoPromocional ?? 0) >
                                                  0 &&
                                              (item.precoPromocional ?? 0) <
                                                  (item.preco ?? 0))
                                            Row(
                                              children: [
                                                Text(
                                                  'R\$ ${(item.preco ?? 0).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    decoration:
                                                        TextDecoration
                                                            .lineThrough,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'R\$ ${(item.precoPromocional ?? 0).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              'R\$ ${(item.preco ?? 0).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                          const SizedBox(height: 4),
                                          const Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),                                  
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
