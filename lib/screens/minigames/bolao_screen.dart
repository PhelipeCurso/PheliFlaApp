import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Paleta & constantes visuais ─────────────────────────────────────────────

const _kRed = Color(0xFFB71C1C);
const _kRedLight = Color(0xFFE53935);
const _kBlack = Color(0xFF0D0D0D);
const _kCardDark = Color(0xFF1A1A1A);
const _kCardLight = Color(0xFFFAFAFA);
const _kGold = Color(0xFFFFB300);

class BolaoScreen extends StatefulWidget {
  const BolaoScreen({super.key});

  @override
  State<BolaoScreen> createState() => _BolaoScreenState();
}

class _BolaoScreenState extends State<BolaoScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _notificar(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w600)),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _kBlack : const Color(0xFFF2F2F2),
      body: CustomScrollView(
        slivers: [
          // ── AppBar customizada com gradiente ──
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _kRed,
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
                    // Detalhe decorativo
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
                    // Conteúdo do header
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
                                    const Icon(Icons.sports_soccer,
                                        color: _kGold, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'BOLÃO',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
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
                                  'PheliFla',
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
                          // Botão ranking
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/ranking_screen'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _kGold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.emoji_events,
                                      color: _kBlack, size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    'Ranking',
                                    style: TextStyle(
                                      color: _kBlack,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      fontFamily: 'Raleway',
                                    ),
                                  ),
                                ],
                              ),
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

          // ── Lista de jogos ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jogos')
                .where('bolao_ativo', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _kRed),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(isDark: isDark),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final match = snapshot.data!.docs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: JogoCard(
                          idJogo: match.id,
                          uid: _uid,
                          dataJogo: match.data() as Map<String, dynamic>,
                          onNotificar: _notificar,
                          isDark: isDark,
                        ),
                      );
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Estado vazio ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kRed.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.sports_soccer,
                  size: 44, color: _kRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum bolão aberto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Raleway',
                color: isDark ? Colors.white : _kBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fique de olho nos próximos jogos do Mengão! 🦅',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Raleway',
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de jogo ─────────────────────────────────────────────────────────────

class JogoCard extends StatefulWidget {
  final String idJogo;
  final String uid;
  final Map<String, dynamic> dataJogo;
  final Function(String) onNotificar;
  final bool isDark;

  const JogoCard({
    super.key,
    required this.idJogo,
    required this.uid,
    required this.dataJogo,
    required this.onNotificar,
    required this.isDark,
  });

  @override
  State<JogoCard> createState() => _JogoCardState();
}

class _JogoCardState extends State<JogoCard> {
  final _contFla = TextEditingController();
  final _contAdv = TextEditingController();
  bool _enviando = false;
  bool _carregandoPalpite = true;
  bool _palpiteConfirmado = false;

  @override
  void initState() {
    super.initState();
    _buscarPalpiteExistente();
  }

  @override
  void dispose() {
    _contFla.dispose();
    _contAdv.dispose();
    super.dispose();
  }

  Future<void> _buscarPalpiteExistente() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('palpites')
          .doc('${widget.idJogo}_${widget.uid}')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _contFla.text = data['gols_flamengo']?.toString() ?? '';
            _contAdv.text = data['gols_adversario']?.toString() ?? '';
            _palpiteConfirmado = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar palpite: $e');
    } finally {
      if (mounted) setState(() => _carregandoPalpite = false);
    }
  }

  Future<void> _salvarPalpite() async {
    final txtFla = _contFla.text.trim();
    final txtAdv = _contAdv.text.trim();

    if (txtFla.isEmpty || txtAdv.isEmpty) {
      widget.onNotificar('Preencha os dois placares antes de enviar! 📝');
      return;
    }

    setState(() => _enviando = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .get();
      final nome = userDoc.data()?['nomeUsuario'] ??
          userDoc.data()?['nome'] ??
          'Torcedor';

      await FirebaseFirestore.instance
          .collection('palpites')
          .doc('${widget.idJogo}_${widget.uid}')
          .set({
        'idJogo': widget.idJogo,
        'idUsuario': widget.uid,
        'nomeUsuario': nome,
        'gols_flamengo': int.parse(txtFla),
        'gols_adversario': int.parse(txtAdv),
        'pontosGanhos': 0,
        'processado': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) setState(() => _palpiteConfirmado = true);
      widget.onNotificar('Palpite registrado! Boa sorte! 🔴⚫');
    } catch (e) {
      widget.onNotificar('Erro ao salvar palpite.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adversario = widget.dataJogo['adversario'] ?? 'Adversário';
    final competicao = widget.dataJogo['competicao'] ?? 'Partida';
    final dataJogo = widget.dataJogo['data'] ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: widget.isDark
            ? const LinearGradient(
                colors: [Color(0xFF1C1C1C), Color(0xFF232323)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: _kRed.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _carregandoPalpite
            ? const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(color: _kRed, strokeWidth: 2),
                ),
              )
            : Column(
                children: [
                  // ── Faixa superior com badge de competição ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kBlack, _kRed],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_soccer,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            competicao.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Raleway',
                              letterSpacing: 1.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dataJogo.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.white70, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  dataJogo,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Área do placar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Time da casa — Flamengo
                            Expanded(
                              child: Column(
                                children: [
                                  _TeamLogo(
                                    isFlamengo: true,
                                    isDark: widget.isDark,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Flamengo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Raleway',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Inputs de placar
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  _ScoreInput(
                                    controller: _contFla,
                                    isDark: widget.isDark,
                                    enabled: !_palpiteConfirmado && !_enviando,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      'x',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        fontFamily: 'Raleway',
                                        color: widget.isDark
                                            ? Colors.white38
                                            : Colors.black26,
                                      ),
                                    ),
                                  ),
                                  _ScoreInput(
                                    controller: _contAdv,
                                    isDark: widget.isDark,
                                    enabled: !_palpiteConfirmado && !_enviando,
                                  ),
                                ],
                              ),
                            ),

                            // Time visitante — Adversário
                            Expanded(
                              child: Column(
                                children: [
                                  _TeamLogo(
                                    isFlamengo: false,
                                    isDark: widget.isDark,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    adversario,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Raleway',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Botão de confirmação / Estado Confirmado ──
                        _palpiteConfirmado
                            ? _ConfirmedBadge(isDark: widget.isDark)
                            : SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _enviando ? null : _salvarPalpite,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kRed,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        _kRed.withValues(alpha: 0.5),
                                    elevation: 4,
                                    shadowColor:
                                        _kRed.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _enviando
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_outline,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Confirmar Palpite',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                fontFamily: 'Raleway',
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text('🎲',
                                                style:
                                                    TextStyle(fontSize: 15)),
                                          ],
                                        ),
                                ),
                              ),

                        // Link para alterar palpite confirmado
                        if (_palpiteConfirmado)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _palpiteConfirmado = false),
                              child: const Text(
                                'Alterar palpite',
                                style: TextStyle(
                                  color: _kRed,
                                  fontSize: 13,
                                  fontFamily: 'Raleway',
                                  fontWeight: FontWeight.w600,
                                ),
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

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _TeamLogo extends StatelessWidget {
  final bool isFlamengo;
  final bool isDark;

  const _TeamLogo({required this.isFlamengo, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isFlamengo
            ? const LinearGradient(
                colors: [_kBlack, _kRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C2C), const Color(0xFF3A3A3A)]
                    : [const Color(0xFFEEEEEE), const Color(0xFFDDDDDD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: (isFlamengo ? _kRed : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: isFlamengo
            ? const Text(
                'CRF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  fontFamily: 'Raleway',
                  letterSpacing: 0.5,
                ),
              )
            : Icon(
                Icons.shield,
                size: 24,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool enabled;

  const _ScoreInput({
    required this.controller,
    required this.isDark,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 58,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 2,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          fontFamily: 'Raleway',
          color: isDark ? Colors.white : _kBlack,
          height: 1,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          counterText: '',
          border: InputBorder.none,
          hintText: '-',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class _ConfirmedBadge extends StatelessWidget {
  final bool isDark;
  const _ConfirmedBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF43A047).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF43A047), size: 18),
          SizedBox(width: 8),
          Text(
            'Palpite confirmado!',
            style: TextStyle(
              color: Color(0xFF43A047),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              fontFamily: 'Raleway',
            ),
          ),
        ],
      ),
    );
  }
}