import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({super.key, required this.Loja});

  final String Loja;

  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  late Future<List<Product>> _produtosFuture;

  String _categoriaSelecionada = 'Todos';
  String _generoSelecionado = 'Todos';
  String _tipoSelecionado = 'Todos';

  bool _showFilters = true;
  bool _dadosIniciaisCarregados = false;

  List<String> categorias = ['Todos'];
  List<String> generos = ['Todos'];
  List<String> tipos = ['Todos'];

  late Map<String, String> categoriaMap;
  late Map<String, String> generoMap;
  late Map<String, String> tipoMap;

  @override
  void initState() {
    super.initState();
    _produtosFuture = carregarProdutos();
  }

  Future<List<Product>> carregarProdutos() async {
    final produtos = await ProductService.fetchProdutos(Loja: widget.Loja);
    final categoriasUnicas = produtos.map((p) => p.categoria).toSet().toList();
    final generosUnicos = produtos.map((p) => p.genero).toSet().toList();
    final tiposUnicos = produtos.map((p) => p.tipo).toSet().toList();

    categorias = ['Todos', ...categoriasUnicas];
    generos = ['Todos', ...generosUnicos];
    tipos = ['Todos', ...tiposUnicos];

    return produtos;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosIniciaisCarregados) {
      final local = AppLocalizations.of(context)!;

      categoriaMap = {
        local.all: 'Todos',
        local.categoryShirts: 'Camisas',
        local.categoryCaps: 'Bonés',
        local.categoryAccessories: 'Acessórios',
        local.categoryMugs: 'Canecas',
        local.categoryCropped: 'Cropped',
        local.categoryBody: 'Body',
        local.categoryKit: 'kit',
      };

      generoMap = {
        local.all: 'Todos',
        local.genderMale: 'Masculino',
        local.genderFemale: 'Feminino',
        local.genderUnisex: 'Unissex',
      };

      tipoMap = {
        local.all: 'Todos',
        local.typeChild: 'Infantil',
        local.typeAdult: 'Adulto',
      };

      Future.delayed(Duration.zero, _mostrarAviso);
      _dadosIniciaisCarregados = true;
    }
  }

  void _mostrarAviso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: const Text(
          'Os valores podem variar no momento da compra. Confirme o valor no app de compra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<Product> _filtrarProdutos(List<Product> produtos) {
    return produtos.where((p) {
      final categoriaOk = _categoriaSelecionada == 'Todos' || p.categoria == _categoriaSelecionada;
      final generoOk = _generoSelecionado == 'Todos' || p.genero == _generoSelecionado;
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
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
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
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(local.category, categorias, _categoriaSelecionada,
                                (value) => setState(() => _categoriaSelecionada = value!)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(local.gender, generos, _generoSelecionado,
                                (value) => setState(() => _generoSelecionado = value!)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(local.type, tipos, _tipoSelecionado,
                          (value) => setState(() => _tipoSelecionado = value!)),
                    ],
                  ),
                ),
              Expanded(
                child: produtos.isEmpty
                    ? Center(child: Text(local.noProducts))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: produtos.length,
                        itemBuilder: (context, index) {
                          final item = produtos[index];
                          return ProductCard(
                            item: item,
                            onTap: () => _abrirLink(item.url),
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

class ProductCard extends StatelessWidget {
  final Product item;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: item.url.isNotEmpty ? onTap : () => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidUrl))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    item.imagem,
                    height: 175,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 175,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 175,
                      child: Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
                if (item.tag.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.tag == 'Promoção' ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if ((item.precoPromocional ?? 0) > 0 &&
                      (item.precoPromocional ?? 0) < (item.preco ?? 0))
                    Row(
                      children: [
                        Text(
                          'R\$ ${(item.preco ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(Icons.shopping_cart_outlined, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
