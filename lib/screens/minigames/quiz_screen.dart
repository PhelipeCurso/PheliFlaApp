import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Paleta — idêntica ao BolaoScreen ────────────────────────────────────────

const _kRed = Color(0xFFB71C1C);
const _kBlack = Color(0xFF0D0D0D);
const _kGold = Color(0xFFFFB300);

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _jaRespondeuHoje = false;
  bool _carregando = true;
  List<DocumentSnapshot> _perguntas = [];
  int _indiceAtual = 0;
  int _acertos = 0;
  int? _opcaoSelecionada;
  bool _respondeuAtual = false; // mostra feedback antes de avançar

  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _verificarStatusQuiz();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  // ─── Lógica ───────────────────────────────────────────────────────────────

  String _obterDataHoje() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _atualizarProgress() {
    final target =
        (_indiceAtual + 1) / (_perguntas.isEmpty ? 1 : _perguntas.length);
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );
    _progressCtrl
      ..reset()
      ..forward();
  }

  Future<void> _verificarStatusQuiz() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(_uid)
              .get();
      final ultimaData = userDoc.data()?['ultimaDataQuiz'] as String? ?? '';
      final hoje = _obterDataHoje();

      if (ultimaData == hoje) {
        setState(() {
          _jaRespondeuHoje = true;
          _carregando = false;
        });
        return;
      }

      final quizSnap =
          await FirebaseFirestore.instance
              .collection('quizzes')
              .where('dataExibicao', isEqualTo: hoje)
              .get();

      setState(() {
        _perguntas = quizSnap.docs;
        _carregando = false;
      });

      if (_perguntas.isNotEmpty) _atualizarProgress();
    } catch (_) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _finalizarQuiz() async {
    final hoje = _obterDataHoje();
    final ontem = DateTime.now().subtract(const Duration(days: 1));
    final strOntem =
        '${ontem.year}-${ontem.month.toString().padLeft(2, '0')}-${ontem.day.toString().padLeft(2, '0')}';

    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(_uid);
    final userDoc = await userRef.get();

    int streakAtual = userDoc.data()?['quizStreak'] ?? 0;
    final ultimaData = userDoc.data()?['ultimaDataQuiz'] as String? ?? '';

    if (_acertos == _perguntas.length && _perguntas.isNotEmpty) {
      streakAtual = (ultimaData == strOntem) ? streakAtual + 1 : 1;
    }

    await userRef.set({
      'ultimaDataQuiz': hoje,
      'quizStreak': streakAtual,
    }, SetOptions(merge: true));

    _mostrarResultadoFinal(streakAtual);
  }

  void _selecionarOpcao(int index) {
    if (_respondeuAtual) return;
    setState(() {
      _opcaoSelecionada = index;
      _respondeuAtual = true;
    });
    final dados = _perguntas[_indiceAtual].data() as Map<String, dynamic>;
    if (index == dados['respostaCorreta']) _acertos++;
  }

  void _proximaPergunta() {
    if (!_respondeuAtual) return;

    if (_indiceAtual + 1 < _perguntas.length) {
      setState(() {
        _indiceAtual++;
        _opcaoSelecionada = null;
        _respondeuAtual = false;
      });
      _atualizarProgress();
    } else {
      _finalizarQuiz();
    }
  }

  // ─── Dialog de resultado ──────────────────────────────────────────────────

  void _mostrarResultadoFinal(int streak) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _perguntas.length;
    final pct = total > 0 ? (_acertos / total * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Troféu animado
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_kBlack, _kRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kRed.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Quiz Concluído!',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : _kBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_acertos de $total perguntas corretas',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Barra de desempenho
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: total > 0 ? _acertos / total : 0,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation(_kRed),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$pct%',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w700,
                        color: _kRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Badge de streak
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          'Ofensiva: $streak dias',
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _kGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: _kRed.withValues(alpha: 0.4),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Voltar para o App',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_carregando) {
      return Scaffold(
        backgroundColor: isDark ? _kBlack : const Color(0xFFF2F2F2),
        body: Center(child: CircularProgressIndicator(color: _kRed)),
      );
    }

    if (_jaRespondeuHoje) return _TelaJaRespondeu(isDark: isDark);
    if (_perguntas.isEmpty) return _TelaSemQuiz(isDark: isDark);

    final perguntaAtual =
        _perguntas[_indiceAtual].data() as Map<String, dynamic>;
    final List<dynamic> opcoes = perguntaAtual['opcoes'];
    final int? correta = perguntaAtual['respostaCorreta'] as int?;
    final total = _perguntas.length;

    return Scaffold(
      backgroundColor: isDark ? _kBlack : const Color(0xFFF2F2F2),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar — mesmo padrão do BolaoScreen ──
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _kRed,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
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
                                    const Text(
                                      '🧠',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'QUIZ',
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
                                  'Histórico',
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
                          // Badge de progresso
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _kGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_indiceAtual + 1} / $total',
                              style: const TextStyle(
                                color: _kBlack,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                fontFamily: 'Raleway',
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

          // ── Conteúdo ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Barra de progresso animada
                _ProgressBar(animation: _progressAnim, isDark: isDark),
                const SizedBox(height: 20),

                // Card da pergunta
                _PerguntaCard(
                  pergunta: perguntaAtual['pergunta'] ?? '',
                  indice: _indiceAtual,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Opções
                ...List.generate(opcoes.length, (i) {
                  OpcaoEstado estado = OpcaoEstado.normal;
                  if (_respondeuAtual) {
                    if (i == correta) {
                      estado = OpcaoEstado.correta;
                    } else if (i == _opcaoSelecionada) {
                      estado = OpcaoEstado.errada;
                    } else {
                      estado = OpcaoEstado.inativa;
                    }
                  } else if (i == _opcaoSelecionada) {
                    estado = OpcaoEstado.selecionada;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OpcaoCard(
                      texto: opcoes[i].toString(),
                      letra: String.fromCharCode(65 + i), // A, B, C, D
                      estado: estado,
                      onTap: () => _selecionarOpcao(i),
                      isDark: isDark,
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Botão avançar
                AnimatedOpacity(
                  opacity: _respondeuAtual ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _respondeuAtual ? _proximaPergunta : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kRed.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: _kRed.withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _indiceAtual + 1 == total
                                ? 'Finalizar Quiz'
                                : 'Próxima Pergunta',
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _indiceAtual + 1 == total
                                ? Icons.emoji_events_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enum estado das opções ───────────────────────────────────────────────────

enum OpcaoEstado { normal, selecionada, correta, errada, inativa }

// ─── Barra de progresso animada ───────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;
  const _ProgressBar({required this.animation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder:
              (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: animation.value,
                  minHeight: 6,
                  backgroundColor:
                      isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(_kRed),
                ),
              ),
        ),
      ],
    );
  }
}

// ─── Card da pergunta ─────────────────────────────────────────────────────────

class _PerguntaCard extends StatelessWidget {
  final String pergunta;
  final int indice;
  final bool isDark;
  const _PerguntaCard({
    required this.pergunta,
    required this.indice,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient:
            isDark
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
            color: _kRed.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Faixa superior — mesmo padrão do BolaoScreen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kBlack, _kRed],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 7),
                  Text(
                    'PERGUNTA ${indice + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Raleway',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Text(
                pergunta,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  color: isDark ? Colors.white : _kBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de opção ────────────────────────────────────────────────────────────

class _OpcaoCard extends StatelessWidget {
  final String texto;
  final String letra;
  final OpcaoEstado estado;
  final VoidCallback onTap;
  final bool isDark;

  const _OpcaoCard({
    required this.texto,
    required this.letra,
    required this.estado,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Cores de acordo com o estado
    final Color borderColor;
    final Color bgColor;
    final Color letraColor;
    final Color letraBg;
    final Color textColor;
    Widget? trailingIcon;

    switch (estado) {
      case OpcaoEstado.correta:
        borderColor = const Color(0xFF43A047).withValues(alpha: 0.6);
        bgColor = const Color(0xFF43A047).withValues(alpha: 0.1);
        letraBg = const Color(0xFF43A047);
        letraColor = Colors.white;
        textColor = const Color(0xFF43A047);
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF43A047),
          size: 20,
        );
        break;
      case OpcaoEstado.errada:
        borderColor = _kRed.withValues(alpha: 0.5);
        bgColor = _kRed.withValues(alpha: 0.08);
        letraBg = _kRed;
        letraColor = Colors.white;
        textColor = _kRed;
        trailingIcon = Icon(
          Icons.cancel_rounded,
          color: _kRed.withValues(alpha: 0.7),
          size: 20,
        );
        break;
      case OpcaoEstado.selecionada:
        borderColor = _kRed;
        bgColor = _kRed.withValues(alpha: 0.08);
        letraBg = _kRed;
        letraColor = Colors.white;
        textColor = isDark ? Colors.white : _kBlack;
        break;
      case OpcaoEstado.inativa:
        borderColor =
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06);
        bgColor = Colors.transparent;
        letraBg =
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05);
        letraColor = isDark ? Colors.white24 : Colors.black26;
        textColor = isDark ? Colors.white24 : Colors.black26;
        break;
      case OpcaoEstado.normal:
        borderColor =
            isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08);
        bgColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        letraBg =
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _kRed.withValues(alpha: 0.08);
        letraColor = _kRed;
        textColor = isDark ? Colors.white : _kBlack;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow:
            estado == OpcaoEstado.normal
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: estado == OpcaoEstado.normal ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Badge da letra
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: letraBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      letra,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: letraColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  trailingIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tela: já respondeu hoje ──────────────────────────────────────────────────

class _TelaJaRespondeu extends StatelessWidget {
  final bool isDark;
  const _TelaJaRespondeu({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? _kBlack : const Color(0xFFF2F2F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _kRed,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kBlack, _kRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🧠', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'QUIZ',
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
                      const Text(
                        'Histórico',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kGold.withValues(alpha: 0.12),
                      border: Border.all(
                        color: _kGold.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text('✅', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Você já jogou hoje!',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : _kBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Volte amanhã para manter sua\nofensiva viva. 🔥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 15,
                      height: 1.55,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: _kRed.withValues(alpha: 0.35),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Voltar para o App',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tela: sem quiz hoje ──────────────────────────────────────────────────────

class _TelaSemQuiz extends StatelessWidget {
  final bool isDark;
  const _TelaSemQuiz({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? _kBlack : const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        title: const Text(
          'Quiz Histórico',
          style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                child: const Center(
                  child: Icon(
                    Icons.hourglass_empty_rounded,
                    size: 42,
                    color: _kRed,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhum quiz hoje',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : _kBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O quiz do dia ainda não foi publicado.\nVolte mais tarde! ⏳',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
