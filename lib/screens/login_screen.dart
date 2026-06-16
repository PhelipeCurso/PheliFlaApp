import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:pheli_fla_app/gen_l10n/app_localizations.dart'; // descomente no seu projeto

// ═══════════════════════════════════════════════════════════════════
// CONSTANTES — centraliza magic strings e evita typos espalhados
// ═══════════════════════════════════════════════════════════════════

abstract class _K {
  // SharedPreferences
  static const String lembrarLogin  = 'lembrarLogin';
  static const String emailSalvo    = 'email_salvo';
  static const String useBiometric  = 'use_biometric';

  // SecureStorage
  static const String bioEmail = 'bio_email';
  static const String bioSenha = 'bio_senha';

  // Rotas
  static const String routeHome     = '/home_screen';
  static const String routeRegister = '/register';

  // Firebase Auth — códigos de erro unificados no SDK v4+
  static const Set<String> invalidCredentialCodes = {
    'wrong-password',
    'user-not-found',
    'invalid-credential',
    'INVALID_LOGIN_CREDENTIALS',
  };
}

// ═══════════════════════════════════════════════════════════════════
// SERVIÇO DE AUTENTICAÇÃO — separa lógica de negócio da UI
// (Single Responsibility — SOLID)
// ═══════════════════════════════════════════════════════════════════

class _AuthService {
  static final FirebaseAuth      _auth      = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Sessão ──────────────────────────────────────────────────────

  /// Retorna o usuário atual com token renovado, ou null se sessão inválida.
  static Future<User?> getValidatedCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      await user.getIdToken(true);
      return _auth.currentUser; // pode ser null se signOut foi chamado acima
    } catch (_) {
      await _auth.signOut();
      return null;
    }
  }

  // ── Firestore ───────────────────────────────────────────────────

  static Future<String> fetchNomeUsuario(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    return doc.data()?['nomeUsuario'] as String? ?? 'Usuário';
  }

  static Future<void> upsertUsuarioGoogle({
    required String uid,
    required String nome,
    required String email,
  }) async {
    final docRef = _firestore.collection('usuarios').doc(uid);
    final doc    = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'nomeUsuario'  : nome,
        'email'        : email,
        'dataCadastro' : FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Login ────────────────────────────────────────────────────────

  static Future<UserCredential> loginEmailSenha(
      String email, String senha) =>
      _auth.signInWithEmailAndPassword(email: email, password: senha);

  static Future<UserCredential?> loginGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<void> resetSenha(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Biometria ────────────────────────────────────────────────────

  static Future<void> salvarCredenciaisBiometricas(
      String email, String senha) async {
    await _secureStorage.write(key: _K.bioEmail, value: email);
    await _secureStorage.write(key: _K.bioSenha, value: senha);
  }

  static Future<({String? email, String? senha})> lerCredenciaisBiometricas() async {
    final email = await _secureStorage.read(key: _K.bioEmail);
    final senha = await _secureStorage.read(key: _K.bioSenha);
    return (email: email, senha: senha);
  }

  static Future<void> limparCredenciaisBiometricas() async {
    await _secureStorage.delete(key: _K.bioEmail);
    await _secureStorage.delete(key: _K.bioSenha);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_K.useBiometric);
  }

  // ── FCM ──────────────────────────────────────────────────────────

  static Future<void> atualizarFcmToken(String uid, String nome) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings  = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      final token = await messaging
          .getToken()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (token == null) return;

      await _firestore.collection('usuarios').doc(uid).set({
        'fcmToken'        : token,
        'nomeUsuario'     : nome,
        'isOnline'        : true,
        'ultimaAtividade' : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM Token atualizado: $nome');
    } catch (e) {
      debugPrint('⚠️ FCM: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL
// ═══════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────
  final _formKey         = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _emailFocus      = FocusNode();
  final _senhaFocus      = FocusNode();
  final _localAuth       = LocalAuthentication();

  // ── Estado ───────────────────────────────────────────────────────
  bool _isLoading    = false;
  bool _mostrarSenha = false;
  bool _lembrarLogin = false;

  // Animação de entrada do card
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Ciclo de vida ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Configura animação de entrada
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _carregarPreferencias();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animCtrl.forward();
      _verificarSessaoEBiometria();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  // ── Verificação de sessão + biometria ────────────────────────────

  Future<void> _verificarSessaoEBiometria() async {
    try {
      // 1. Se já existe sessão válida → vai direto para home
      final user = await _AuthService.getValidatedCurrentUser();
      if (user != null && mounted) {
        final nome = await _AuthService.fetchNomeUsuario(user.uid);
        _navegarParaHome(nome);
        return;
      }

      // 2. Verifica suporte e preferência do usuário
      final bool suporta = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!suporta || !mounted) return;

      final prefs   = await SharedPreferences.getInstance();
      final ativada = prefs.getBool(_K.useBiometric) ?? false;
      if (!ativada) return;

      // 3. Só exibe se houver credenciais salvas (nunca para Google)
      final creds = await _AuthService.lerCredenciaisBiometricas();
      if (creds.email == null || creds.senha == null) return;

      if (mounted) await _exibirDialogBiometria();

    } catch (e) {
      debugPrint('⚠️ _verificarSessaoEBiometria: $e');
    }
  }

  // ── Biometria ────────────────────────────────────────────────────

  Future<void> _exibirDialogBiometria() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BiometricDialog(
        onConfirm: () async {
          Navigator.pop(ctx);
          await _loginComBiometria();
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _loginComBiometria() async {
    if (!mounted) return;
    _setLoading(true);

    try {
      final autenticado = await _localAuth.authenticate(
        localizedReason: 'Use sua digital ou rosto para entrar no app',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticação Biométrica',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(cancelButton: 'Cancelar'),
        ],
      );
      if (!autenticado || !mounted) return;

      final creds = await _AuthService.lerCredenciaisBiometricas();
      if (creds.email == null || creds.senha == null) {
        await _AuthService.limparCredenciaisBiometricas();
        _mostrarErro('Configure a biometria novamente fazendo login com e-mail e senha.');
        return;
      }

      final userCred = await _AuthService.loginEmailSenha(
          creds.email!, creds.senha!);
      final uid  = userCred.user!.uid;
      final nome = await _AuthService.fetchNomeUsuario(uid);

      await _AuthService.atualizarFcmToken(uid, nome);
      if (mounted) _navegarParaHome(nome);

    } on FirebaseAuthException catch (e) {
      if (_K.invalidCredentialCodes.contains(e.code)) {
        await _AuthService.limparCredenciaisBiometricas();
        _mostrarErro('Senha alterada. Faça login com e-mail e senha para reativar a biometria.');
      } else {
        _mostrarErro(_mensagemFirebase(e));
      }
    } catch (e) {
      _mostrarErro('Erro inesperado. Tente fazer login manualmente.');
      debugPrint('❌ _loginComBiometria: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Login e-mail/senha ───────────────────────────────────────────

  Future<void> _login() async {
    // Fecha o teclado antes de validar
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    // Captura valores ANTES dos awaits (segurança contra dispose)
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    try {
      final userCred = await _AuthService.loginEmailSenha(email, senha);
      final uid      = userCred.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception('Usuário não encontrado no banco de dados.');

      final nome = doc['nomeUsuario'] as String;
      await _AuthService.atualizarFcmToken(uid, nome);
      await _salvarPreferencias();
      await _checarAtivacaoBiometria(nome, email, senha);

    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mensagemFirebase(e));
    } catch (e) {
      _mostrarErro('Ocorreu um erro inesperado.');
      debugPrint('❌ _login: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Login Google ─────────────────────────────────────────────────

  Future<void> _loginGoogle() async {
    FocusScope.of(context).unfocus();
    _setLoading(true);

    try {
      final userCred = await _AuthService.loginGoogle();
      if (userCred == null || !mounted) return; // usuário cancelou

      final uid        = userCred.user!.uid;
      final googleUser = userCred.user!;
      final nome       = googleUser.displayName ?? 'Usuário Google';

      await _AuthService.upsertUsuarioGoogle(
        uid:   uid,
        nome:  nome,
        email: googleUser.email ?? '',
      );
      await _AuthService.atualizarFcmToken(uid, nome);
      if (mounted) _navegarParaHome(nome);

    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mensagemFirebase(e));
    } catch (e) {
      _mostrarErro('Erro ao entrar com o Google.');
      debugPrint('❌ _loginGoogle: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Recuperação de senha ─────────────────────────────────────────

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();

    // Valida apenas o campo e-mail
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _mostrarErro('Insira um e-mail válido para recuperar a senha.');
      _emailFocus.requestFocus();
      return;
    }

    _setLoading(true);
    try {
      await _AuthService.resetSenha(email);
      _mostrarSucesso('E-mail de recuperação enviado! Verifique sua caixa de entrada.');
    } on FirebaseAuthException catch (e) {
      _mostrarErro(_mensagemFirebase(e));
    } catch (_) {
      _mostrarErro('Ocorreu um erro inesperado.');
    } finally {
      _setLoading(false);
    }
  }

  // ── Fluxo pós-login: oferecer biometria ─────────────────────────

  Future<void> _checarAtivacaoBiometria(
      String nome, String email, String senha) async {
    final prefs   = await SharedPreferences.getInstance();
    final suporta = await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();

    // Exibe apenas UMA VEZ e só se o dispositivo suportar
    if (prefs.getBool(_K.useBiometric) == null && suporta && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _AtivarBiometriaDialog(
          onAtivar: () async {
            await _AuthService.salvarCredenciaisBiometricas(email, senha);
            await prefs.setBool(_K.useBiometric, true);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onRecusar: () async {
            await prefs.setBool(_K.useBiometric, false);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      );
    }

    if (mounted) _navegarParaHome(nome);
  }

  // ── Preferências ─────────────────────────────────────────────────

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lembrarLogin = prefs.getBool(_K.lembrarLogin) ?? false;
      if (_lembrarLogin) {
        _emailController.text = prefs.getString(_K.emailSalvo) ?? '';
      }
    });
  }

  Future<void> _salvarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lembrarLogin) {
      await prefs.setString(_K.emailSalvo, _emailController.text.trim());
      await prefs.setBool(_K.lembrarLogin, true);
    } else {
      await prefs.remove(_K.emailSalvo);
      await prefs.setBool(_K.lembrarLogin, false);
    }
  }

  // ── Navegação ────────────────────────────────────────────────────

  void _navegarParaHome(String nome) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, _K.routeHome, arguments: nome);
  }

  // ── Helpers ──────────────────────────────────────────────────────

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  /// Mapeia FirebaseAuthException para mensagens amigáveis em português.
  String _mensagemFirebase(FirebaseAuthException e) {
    return switch (e.code) {
      'network-request-failed'    => 'Sem internet. Verifique sua conexão.',
      'user-disabled'             => 'Esta conta foi desativada.',
      'user-not-found'            => 'E-mail não cadastrado.',
      'wrong-password'            => 'Senha incorreta.',
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' => 'E-mail ou senha inválidos.',
      'too-many-requests'         => 'Muitas tentativas. Tente novamente mais tarde.',
      'email-already-in-use'      => 'Este e-mail já está em uso.',
      _                           => e.message ?? 'Erro de autenticação.',
    };
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  // ── Decoração dos campos ─────────────────────────────────────────

  InputDecoration _inputStyle(String label, IconData icon, bool isDark) {
    final labelColor   = isDark ? Colors.white70  : Colors.black54;
    final primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;
    final borderColor  = isDark ? Colors.white24  : Colors.black12;

    return InputDecoration(
      labelText:           label,
      labelStyle:          TextStyle(color: labelColor),
      floatingLabelStyle:  TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
      prefixIcon:          Icon(icon, color: primaryColor, size: 22),
      border:              OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder:       OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:   BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:   BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:   BorderSide(color: Colors.red[300]!, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:   BorderSide(color: Colors.red[400]!, width: 2),
      ),
      filled:    true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;
    // final l10n      = AppLocalizations.of(context)!; // descomente no seu projeto

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Adapta a barra de status ao fundo escuro da tela
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Fundo ──────────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/PheliFlafundo.png',
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.52)),

            // ── Conteúdo ───────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1A1A).withValues(alpha: 0.82)
                              : Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color:      Colors.black45,
                              blurRadius: 24,
                              offset:     Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // ── Logo / título ───────────────────
                              _buildHeader(primaryColor),
                              const SizedBox(height: 28),

                              // ── Campo e-mail ────────────────────
                              TextFormField(
                                controller:      _emailController,
                                focusNode:       _emailFocus,
                                style:           TextStyle(
                                    color: isDark ? Colors.white : Colors.black87),
                                decoration:      _inputStyle('E-mail', Icons.email_outlined, isDark),
                                keyboardType:    TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect:     false,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).requestFocus(_senhaFocus),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu e-mail';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                      .hasMatch(v.trim())) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Campo senha ─────────────────────
                              TextFormField(
                                controller:      _senhaController,
                                focusNode:       _senhaFocus,
                                style:           TextStyle(
                                    color: isDark ? Colors.white : Colors.black87),
                                obscureText:     !_mostrarSenha,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _isLoading ? null : _login(),
                                decoration:
                                    _inputStyle('Senha', Icons.lock_outline, isDark)
                                        .copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _mostrarSenha
                                        ? 'Ocultar senha'
                                        : 'Mostrar senha',
                                    icon: Icon(
                                      _mostrarSenha
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                      size: 22,
                                    ),
                                    onPressed: () => setState(
                                        () => _mostrarSenha = !_mostrarSenha),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe sua senha';
                                  }
                                  if (v.length < 6) {
                                    return 'A senha deve ter ao menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),

                              // ── Lembrar + Esqueci ───────────────
                              _buildLembrarRow(isDark, primaryColor),
                              const SizedBox(height: 20),

                              // ── Botão entrar ────────────────────
                              _buildBotaoLogin(primaryColor),
                              const SizedBox(height: 24),

                              // ── Divisor "ou" ────────────────────
                              _buildDivisor(isDark),
                              const SizedBox(height: 24),

                              // ── Botão Google ────────────────────
                              _buildBotaoGoogle(isDark),
                              const SizedBox(height: 24),

                              // ── Link cadastro ───────────────────
                              _buildLinkCadastro(primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Loading overlay global ─────────────────────────────
            if (_isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.20),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────

  Widget _buildHeader(Color primaryColor) {
    return Column(
      children: [
        Icon(Icons.sports_soccer_rounded, color: primaryColor, size: 48),
        const SizedBox(height: 12),
        Text(
          'Bem-vindo de volta!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   26,
            fontWeight: FontWeight.bold,
            color:      primaryColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faça login para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color:    primaryColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLembrarRow(bool isDark, Color primaryColor) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value:       _lembrarLogin,
            activeColor: primaryColor,
            checkColor:  Colors.white,
            side: BorderSide(
                color: isDark ? Colors.white54 : Colors.black38),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            onChanged: (v) => setState(() => _lembrarLogin = v!),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _lembrarLogin = !_lembrarLogin),
          child: Text(
            'Lembrar meu e-mail',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : _recuperarSenha,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Esqueci minha senha',
            style: TextStyle(
              fontSize:   13,
              color:      isDark ? Colors.blueAccent : Colors.blue[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoLogin(Color primaryColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        key: ValueKey(_isLoading),
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            shadowColor: primaryColor.withValues(alpha: 0.4),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Entrar',
                  style: TextStyle(
                    fontSize:    16,
                    fontWeight:  FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivisor(bool isDark) {
    final dividerColor = isDark ? Colors.white38 : Colors.black12;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ou continue com',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }

  Widget _buildBotaoGoogle(bool isDark) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _loginGoogle,
        icon: Icon(
          Icons.g_mobiledata_rounded,
          size:  28,
          color: isDark ? Colors.white : Colors.black87,
        ),
        label: Text(
          'Entrar com Google',
          style: TextStyle(
            color:      isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize:   15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildLinkCadastro(Color primaryColor) {
    return TextButton(
      onPressed: () =>
          Navigator.pushNamed(context, _K.routeRegister),
      child: RichText(
        text: TextSpan(
          text: 'Não tem uma conta? ',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          children: [
            TextSpan(
              text: 'Cadastre-se',
              style: TextStyle(
                color:      primaryColor,
                fontWeight: FontWeight.bold,
                fontSize:   14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DIALOG — Usar biometria ao abrir o app
// ═══════════════════════════════════════════════════════════════════

class _BiometricDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BiometricDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone em destaque
            Container(
              width:  84,
              height: 84,
              decoration: BoxDecoration(
                color:  primaryColor.withValues(alpha: 0.12),
                shape:  BoxShape.circle,
              ),
              child: Icon(Icons.fingerprint, size: 50, color: primaryColor),
            ),
            const SizedBox(height: 20),

            Text(
              'Acesso Biométrico',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'Use sua digital ou reconhecimento facial para entrar rapidamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height:   1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),

            // Botão confirmar
            SizedBox(
              width:  double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: const Text(
                  'Usar Biometria',
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botão cancelar
            SizedBox(
              width:  double.infinity,
              height: 46,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: isDark ? Colors.white38 : Colors.black12),
                  ),
                ),
                child: Text(
                  'Usar e-mail e senha',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DIALOG — Ativar biometria após o primeiro login
// ═══════════════════════════════════════════════════════════════════

class _AtivarBiometriaDialog extends StatelessWidget {
  final VoidCallback onAtivar;
  final VoidCallback onRecusar;

  const _AtivarBiometriaDialog({
    required this.onAtivar,
    required this.onRecusar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        children: [
          Icon(Icons.lock_open_rounded, color: primaryColor, size: 26),
          const SizedBox(width: 10),
          const Text(
            'Acesso Rápido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: const Text(
        'Quer ativar a biometria (digital ou Face ID) para entrar sem digitar a senha nas próximas vezes?',
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: onRecusar,
          child: const Text(
            'Agora não',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAtivar,
          icon: const Icon(Icons.fingerprint, size: 20, color: Colors.white),
          label: const Text(
            'Ativar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}