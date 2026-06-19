import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/product_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ATENÇÃO — Product model
// Adicione o campo abaixo em lib/models/product.dart:
//
//   final bool entregaFull;
//
//   // No construtor:
//   this.entregaFull = false,
//
//   // No fromMap / fromFirestore:
//   entregaFull: (map['entregaFull'] as bool?) ?? false,
//
//   // No toMap (se houver):
//   'entregaFull': entregaFull,
// ─────────────────────────────────────────────────────────────────────────────

class _VisualConfig {
  final Color primaryColor;
  final Color accentColor;
  final Color chipSelectedColor;
  final String buttonText;
  final IconData storeIcon;

  _VisualConfig({
    required this.primaryColor,
    required this.accentColor,
    required this.chipSelectedColor,
    required this.buttonText,
    required this.storeIcon,
  });

  factory _VisualConfig.fromPlataforma(String plataforma) {
    if (plataforma == 'mercado_livre') {
      return _VisualConfig(
        primaryColor: const Color(0xFFFFF159),
        accentColor: const Color(0xFF2D3277),
        chipSelectedColor: const Color(0xFFFFF159).withOpacity(0.4),
        buttonText: 'VER NO MERCADO LIVRE',
        storeIcon: Icons.handshake_outlined,
      );
    } else {
      return _VisualConfig(
        primaryColor: const Color(0xEEEE4D2D),
        accentColor: const Color(0xEEEE4D2D),
        chipSelectedColor: const Color(0xEEEE4D2D).withOpacity(0.2),
        buttonText: 'VER NA SHOPEE',
        storeIcon: Icons.shopping_bag_outlined,
      );
    }
  }
}

// Cores e constantes do badge Full — centralizadas para fácil manutenção
abstract class _FullBadgeStyle {
  static const Color bgStart = Color(0xFFFFD000);
  static const Color bgEnd = Color(0xFFFF9900);
  static const Color textColor = Color(0xFF1A1200);
  static const Color chipSelected = Color(0xFFFFD000);
  static const Color chipCheck = Color(0xFF1A1200);
}

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

class _LojaScreenState extends State<LojaScreen>
    with SingleTickerProviderStateMixin {
  late Stream<List<Product>> _produtosStream;
  late TabController _tabController;

  String _plataformaSelecionada = 'shopee';
  String _categoriaSelecionada = 'Todos';
  String _generoSelecionado = 'Todos';
  // Filtro Full: false = todos, true = somente Full
  bool _filtroFullAtivo = false;

  @override
  void initState() {
    super.initState();
    _produtosStream = ProductService.streamProdutos(Loja: widget.Loja);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _plataformaSelecionada =
            _tabController.index == 0 ? 'shopee' : 'mercado_livre';
        // Reseta todos os filtros ao trocar de plataforma
        _categoriaSelecionada = 'Todos';
        _generoSelecionado = 'Todos';
        _filtroFullAtivo = false;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarAviso());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _mostrarAviso() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Atenção'),
              ],
            ),
            content: const Text(
              'Os valores podem variar no momento da compra. '
              'Confirme o preço final no aplicativo da loja.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ENTENDI'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    final configVis = _VisualConfig.fromPlataforma(_plataformaSelecionada);

    return Scaffold(
      body: StreamBuilder<List<Product>>(
        stream: _produtosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar produtos.'));
          }

          final todosProdutos = snapshot.data ?? [];

          final categoriasDinamicas = [
            'Todos',
            ...todosProdutos.map((p) => p.categoria).toSet(),
          ];
          final generosDinamicos = [
            'Todos',
            ...todosProdutos.map((p) => p.genero).toSet(),
          ];

          // Verifica se há ao menos 1 produto Full na plataforma ativa para
          // decidir se o chip de filtro deve aparecer
          final temProdutoFull = todosProdutos.any(
            (p) => p.plataforma == _plataformaSelecionada && p.entregaFull,
          );

          final produtosFiltrados = _filtrarProdutos(todosProdutos);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, configVis),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros de categoria e gênero
                    _buildFilterRow(
                      categoriasDinamicas,
                      _categoriaSelecionada,
                      configVis,
                      (val) => setState(() => _categoriaSelecionada = val),
                    ),
                    _buildFilterRow(
                      generosDinamicos,
                      _generoSelecionado,
                      configVis,
                      (val) => setState(() => _generoSelecionado = val),
                    ),

                    // Filtro Full — só exibe se houver produtos Full nessa plataforma
                    if (temProdutoFull) _buildFullFilterRow(),

                    const Divider(height: 1),
                  ],
                ),
              ),

              produtosFiltrados.isEmpty
                  ? SliverFillRemaining(
                    child: Center(child: Text(local.noProducts)),
                  )
                  : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.60,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ProductCard(
                          item: produtosFiltrados[index],
                          configVis: configVis,
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

  // ── Filtro Full ─────────────────────────────────────────────────────────────
  // Chip independente com identidade visual própria (âmbar), separado dos
  // demais para deixar claro ao usuário que é um filtro de entrega, não de
  // categoria.
  Widget _buildFullFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          FilterChip(
            avatar: const Icon(
              Icons.bolt_rounded,
              size: 16,
              color: _FullBadgeStyle.textColor,
            ),
            label: const Text('Entrega Full'),
            selected: _filtroFullAtivo,
            onSelected:
                (_) => setState(() => _filtroFullAtivo = !_filtroFullAtivo),
            selectedColor: _FullBadgeStyle.chipSelected,
            checkmarkColor: _FullBadgeStyle.chipCheck,
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
            labelStyle: TextStyle(
              color:
                  _filtroFullAtivo
                      ? _FullBadgeStyle.textColor
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87),
              fontWeight:
                  _filtroFullAtivo ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Demais builders ─────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context, _VisualConfig config) {
    final isMl = _plataformaSelecionada == 'mercado_livre';

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: config.primaryColor,
      iconTheme: IconThemeData(color: isMl ? config.accentColor : Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 62),
        title: Text(
          widget.Loja,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isMl ? config.accentColor : Colors.white,
          ),
        ),
        background:
            widget.heroTag != null
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: config.accentColor,
            labelColor: config.accentColor,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [Tab(text: "🔥 SHOPEE"), Tab(text: "⚡ MERCADO LIVRE")],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(
    List<String> items,
    String selected,
    _VisualConfig config,
    Function(String) onSelect,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children:
            items.map((item) {
              final isSelected = selected == item;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (_) => onSelect(item),
                  selectedColor: config.chipSelectedColor,
                  checkmarkColor: config.accentColor,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? config.accentColor
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  List<Product> _filtrarProdutos(List<Product> produtos) {
    return produtos.where((p) {
      final plataformaOk = p.plataforma == _plataformaSelecionada;
      final catOk =
          _categoriaSelecionada == 'Todos' ||
          p.categoria == _categoriaSelecionada;
      final genOk =
          _generoSelecionado == 'Todos' || p.genero == _generoSelecionado;
      // Quando o filtro Full está ativo, exibe apenas produtos Full
      final fullOk = !_filtroFullAtivo || p.entregaFull;

      return plataformaOk && catOk && genOk && fullOk;
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

// ─────────────────────────────────────────────────────────────────────────────
// Card de produto
// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product item;
  final _VisualConfig configVis;
  final VoidCallback onTap;

  const _ProductCard({
    required this.item,
    required this.configVis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        (item.precoPromocional ?? 0) > 0 &&
        (item.precoPromocional ?? 0) < (item.preco ?? 0);

    return GestureDetector(
      onTap: item.url.isNotEmpty ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagem + badges ──────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.imagem,
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(color: Colors.grey[200]),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.broken_image),
                  ),
                ),

                // Badge de tag existente (Promoção etc.) — top-left
                if (item.tag.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            item.tag == 'Promoção'
                                ? Colors.green
                                : const Color(0xFFCB1B1B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Badge Full — bottom-right, oposto ao badge de tag
                // para não colidir quando ambos estão presentes.
                if (item.entregaFull) const _FullBadge(),
              ],
            ),

            // ── Info do produto ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (hasDiscount) ...[
                    Text(
                      'R\$ ${item.preco?.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      'R\$ ${item.precoPromocional?.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: configVis.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      'R\$ ${item.preco?.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Botão de ação
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: configVis.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          configVis.storeIcon,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            configVis.buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Badge Full — widget isolado para fácil reutilização em outras telas
// ─────────────────────────────────────────────────────────────────────────────
class _FullBadge extends StatelessWidget {
  const _FullBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_FullBadgeStyle.bgStart, _FullBadgeStyle.bgEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _FullBadgeStyle.bgEnd.withOpacity(0.45),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 11,
              color: _FullBadgeStyle.textColor,
            ),
            SizedBox(width: 2),
            Text(
              'FULL',
              style: TextStyle(
                color: _FullBadgeStyle.textColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
