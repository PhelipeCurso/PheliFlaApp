import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Paleta & constantes visuais (Idênticas ao Bolão) ───────────────────────

const _kRed = Color(0xFFB71C1C);
const _kRedLight = Color(0xFFE53935);
const _kBlack = Color(0xFF0D0D0D);
const _kCardDark = Color(0xFF1A1A1A);
const _kCardLight = Color(0xFFFAFAFA);
const _kGold = Color(0xFFFFB300);

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _kBlack : const Color(0xFFF2F2F2),
      body: CustomScrollView(
        slivers: [
          // ── AppBar customizada com gradiente e círculos decorativos ──
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kBlack, _kRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Detalhes decorativos idênticos à tela do Bolão
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                    // Conteúdo do cabeçalho
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: _kGold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CLASSIFICAÇÃO',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                        letterSpacing: 3,
                                        fontFamily: 'Raleway',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Ranking PheliFla',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
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
            ),
          ),

          // ── Lista do Ranking com StreamBuilder integrado aos Slivers ──
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('usuarios')
                    .orderBy('pontos_bolao', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _kRed)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Nenhum dado de ranking computado ainda.',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = snapshot.data!.docs[index];
                    final userData = user.data() as Map<String, dynamic>;

                    // Fallbacks idênticos aos padrões do ecossistema PheliFla
                    final pontos = userData['pontos_bolao'] ?? 0;
                    final nomeTorcedor =
                        userData['nome'] ??
                        userData['nomeUsuario'] ??
                        'Torcedor Fla';
                    final posicao = index + 1;

                    // Construção visual do indicador de posição (Medalhas para o Top 3)
                    Widget badgePosicao;
                    if (posicao == 1) {
                      badgePosicao = const Text(
                        '🥇',
                        style: TextStyle(fontSize: 24),
                      );
                    } else if (posicao == 2) {
                      badgePosicao = const Text(
                        '🥈',
                        style: TextStyle(fontSize: 24),
                      );
                    } else if (posicao == 3) {
                      badgePosicao = const Text(
                        '🥉',
                        style: TextStyle(fontSize: 24),
                      );
                    } else {
                      badgePosicao = Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                        ),
                        child: Center(
                          child: Text(
                            '$posicaoº',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? _kCardDark : _kCardLight,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                          if (posicao == 1)
                            BoxShadow(
                              color: _kGold.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                        border: Border.all(
                          color:
                              posicao == 1
                                  ? _kGold.withValues(alpha: 0.3)
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                          width: posicao == 1 ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(child: badgePosicao),
                        ),
                        title: Text(
                          nomeTorcedor,
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark ? Colors.white : _kBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                posicao <= 3
                                    ? _kRed.withValues(alpha: 0.12)
                                    : isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pontos pts',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color:
                                  posicao <= 3
                                      ? _kRedLight
                                      : (isDark ? Colors.white70 : _kBlack),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: snapshot.data!.docs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
