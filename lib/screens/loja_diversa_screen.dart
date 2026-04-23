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
    this.bannerImage, // Adicionei para manter a consistência
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
  String _catSel = 'Todos';
  String _genSel = 'Todos';
  String _tipoSel = 'Todos';

  // Listas de filtros (serão preenchidas dinamicamente)
  List<String> categorias = ['Todos'];
  List<String> generos = ['Todos'];
  List<String> tipos = ['Todos'];

  @override
  void initState() {
    super.initState();
    _produtosFuture = _inicializarDados();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAviso());
  }

  Future<List<Product>> _inicializarDados() async {
    final produtos = await ProductService.fetchProdutos(Loja: widget.Loja);
    
    setState(() {
      categorias = ['Todos', ...produtos.map((p) => p.categoria).toSet()];
      generos = ['Todos', ...produtos.map((p) => p.genero).toSet()];
      tipos = ['Todos', ...produtos.map((p) => p.tipo).toSet()];
    });
    
    return produtos;
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
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produtos.'));
          }

          final listaFiltrada = _filtrar(snapshot.data ?? []);

          return CustomScrollView(
            slivers: [
              // 1. Cabeçalho Animado
              _buildHeader(context),

              // 2. Barra de Filtros (Horizontal)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      _buildChipFilter(categorias, _catSel, (v) => setState(() => _catSel = v)),
                      _buildChipFilter(generos, _genSel, (v) => setState(() => _genSel = v)),
                      _buildChipFilter(tipos, _tipoSel, (v) => setState(() => _tipoSel = v)),
                    ],
                  ),
                ),
              ),

              // 3. Grid de Produtos
              listaFiltrada.isEmpty
                  ? SliverFillRemaining(child: Center(child: Text(local.noProducts)))
                  : SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ProductCard(
                            item: listaFiltrada[index],
                            onTap: () => _abrirLink(listaFiltrada[index].url),
                          ),
                          childCount: listaFiltrada.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.red[900],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.Loja, style: const TextStyle(fontWeight: FontWeight.bold)),
        background: widget.heroTag != null 
          ? Hero(
              tag: widget.heroTag!,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.bannerImage ?? 'assets/images/loja_banner.png', fit: BoxFit.cover),
                  const DecoratedBox(decoration: BoxDecoration(color: Colors.black26)),
                ],
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildChipFilter(List<String> items, String selected, Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: items.map((item) {
          final isSelected = selected == item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (val) => onSelect(item),
              selectedColor: Colors.red[800],
              backgroundColor: Colors.grey[200],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Product> _filtrar(List<Product> lista) {
    return lista.where((p) {
      final c = _catSel == 'Todos' || p.categoria == _catSel;
      final g = _genSel == 'Todos' || p.genero == _genSel;
      final t = _tipoSel == 'Todos' || p.tipo == _tipoSel;
      return c && g && t;
    }).toList();
  }

  // --- Funções de Suporte ---

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  void _mostrarAviso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
}

class _ProductCard extends StatelessWidget {
  final Product item;
  final VoidCallback onTap;

  const _ProductCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: item.url.isNotEmpty ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem com Badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: item.imagem,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[100]),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  if (item.tag.isNotEmpty)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.tag == 'Promoção' ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            
            // Texto e Preços
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nome, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  if ((item.precoPromocional ?? 0) > 0) ...[
                    Text('R\$ ${item.preco?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                    Text('R\$ ${item.precoPromocional?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                  ] else
                    Text('R\$ ${item.preco?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}