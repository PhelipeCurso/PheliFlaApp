import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({
    super.key,
    required this.Loja,
    this.heroTag,
    this.bannerImage,
  });

  final String Loja;
  final String? heroTag;
  final String? bannerImage;

  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> {
  late Future<List<Product>> _produtosFuture;
  
  // Filtros selecionados
  String _categoriaSelecionada = 'Todos';
  String _generoSelecionado = 'Todos';
  
  // Listas dinâmicas vinda do banco
  List<String> categorias = ['Todos'];
  List<String> generos = ['Todos'];

  @override
  void initState() {
    super.initState();
    _produtosFuture = _carregarDados();
    // Mostra o aviso após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAviso());
  }

  Future<List<Product>> _carregarDados() async {
    final produtos = await ProductService.fetchProdutos(Loja: widget.Loja);
    
    setState(() {
      categorias = ['Todos', ...produtos.map((p) => p.categoria).toSet()];
      generos = ['Todos', ...produtos.map((p) => p.genero).toSet()];
    });
    
    return produtos;
  }

  void _mostrarAviso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Atenção'),
          ],
        ),
        content: const Text('Os valores podem variar no momento da compra. Confirme o preço final no aplicativo da loja.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDI')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: FutureBuilder<List<Product>>(
        future: _produtosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final produtosFiltrados = _filtrarProdutos(snapshot.data ?? []);

          return CustomScrollView(
            slivers: [
              // AppBar com imagem dinâmica e efeito Hero
              _buildSliverAppBar(context),

              // Seção de Filtros (Horizontal)
              SliverToBoxAdapter(
                child: _buildFilterSection(local),
              ),

              // Grid de Produtos
              produtosFiltrados.isEmpty
                  ? SliverFillRemaining(child: Center(child: Text(local.noProducts)))
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProductCard(
                            item: produtosFiltrados[index],
                            onTap: () => _abrirLink(produtosFiltrados[index].url),
                          ),
                          childCount: produtosFiltrados.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.red[900],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.Loja, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        background: widget.heroTag != null 
          ? Hero(
              tag: widget.heroTag!,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.bannerImage ?? 'assets/images/loja_banner.png',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.4)),
                ],
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildFilterSection(AppLocalizations local) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(categorias, _categoriaSelecionada, (val) => setState(() => _categoriaSelecionada = val)),
        _buildFilterRow(generos, _generoSelecionado, (val) => setState(() => _generoSelecionado = val)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFilterRow(List<String> items, String selected, Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: items.map((item) {
          final isSelected = selected == item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => onSelect(item),
              selectedColor: Colors.red[100],
              checkmarkColor: Colors.red[900],
              labelStyle: TextStyle(
                color: isSelected ? Colors.red[900] : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Product> _filtrarProdutos(List<Product> produtos) {
    return produtos.where((p) {
      final catOk = _categoriaSelecionada == 'Todos' || p.categoria == _categoriaSelecionada;
      final genOk = _generoSelecionado == 'Todos' || p.genero == _generoSelecionado;
      return catOk && genOk;
    }).toList();
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarErro("Não foi possível abrir o link.");
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ProductCard extends StatelessWidget {
  final Product item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (item.precoPromocional ?? 0) > 0 && (item.precoPromocional ?? 0) < (item.preco ?? 0);

    return GestureDetector(
      onTap: item.url.isNotEmpty ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com Badge de Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: item.imagem,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                  ),
                ),
                if (item.tag.isNotEmpty)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.tag == 'Promoção' ? Colors.green : Colors.red[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            
            // Info do Produto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (hasDiscount) ...[
                    Text(
                      'R\$ ${item.preco?.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                    ),
                    Text(
                      'R\$ ${item.precoPromocional?.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 15, color: Colors.red[900], fontWeight: FontWeight.bold),
                    ),
                  ] else
                    Text(
                      'R\$ ${item.preco?.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 10),
                  
                  // Botão de ação visual
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade900!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'VER NA LOJA',
                        style: TextStyle(color: Colors.red[900], fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}