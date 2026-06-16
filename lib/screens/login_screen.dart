import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ─── Controllers & Keys ───────────────────────────────────────────────────
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _senhaController   = TextEditingController();
  final _localAuth         = LocalAuthentication();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Estado da tela ───────────────────────────────────────────────────────
  bool _isLoading     = false;
  bool _mostrarSenha  = false;
  bool _lembrarLogin  = false;

  // ─── Ciclo de vida ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarEIniciarBiometria();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // ─── Biometria ────────────────────────────────────────────────────────────

  /// FIX PRINCIPAL:
  /// 1. Verifica se o Firebase já tem sessão ativa — se sim, navega direto
  ///    sem mostrar biometria (evita o loop de "sessão expirada").
  /// 2. Só aciona biometria se NÃO houver sessão ativa E houver credenciais
  ///    salvas no secure storage.
  /// 3. Tenta silenciosamente revalidar o token antes de decidir.
  Future<void> _verificarEIniciarBiometria() async {
    try {
      // Passo 1: checa se já existe usuário autenticado no Firebase.
      // Se sim, a sessão persiste — navega direto para home sem biometria.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Tenta revalidar o token de forma silenciosa (força refresh se expirado).
        // Isso resolve o "sessão expirada" causado por token ID vencido.
        try {
          await currentUser.getIdToken(true); // true = forçar refresh
        } catch (_) {
          // Token não renovável (conta deletada, etc.) — prossegue para o login
          await FirebaseAuth.instance.signOut();
        }

        // Após refresh bem-sucedido, usuário ainda está logado — vai para home.
        if (FirebaseAuth.instance.currentUser != null && mounted) {
          final userDoc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(currentUser.uid)
              .get();
          final nome = userDoc.data()?['nomeUsuario'] as String? ?? 'Usuário';
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home_screen', arguments: nome);
          }
          return; // encerra aqui — não mostra biometria
        }
      }

      // Passo 2: Sem sessão ativa. Verifica se o dispositivo suporta biometria.
      final bool suporta = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!suporta || !mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final bool ativada = prefs.getBool('use_biometric') ?? false;

      // Passo 3: Só exibe o popup se houver credenciais de e-mail/senha salvas.
      // Usuários Google nunca chegam aqui com credenciais salvas.
      final String? emailSalvo = await _secureStorage.read(key: 'bio_email');
      final String? senhaSalva = await _secureStorage.read(key: 'bio_senha');
      final bool temCredenciais = emailSalvo != null && senhaSalva != null;

      if (ativada && temCredenciais && mounted) {
        await _exibirPopupBiometrico();
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar biometria: $e');
    }
  }

  Future<void> _exibirPopupBiometrico() async {
    if (!mounted) return;
    await showDialog(
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

  /// Autentica biometricamente e faz login no Firebase com as credenciais
  /// salvas. Tratamento de erros atualizado para o Firebase SDK v4+,
  /// que unificou 'wrong-password' e 'user-not-found' em 'invalid-credential'.
  Future<void> _loginComBiometria() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Prompt biométrico nativo
      final bool autenticado = await _localAuth.authenticate(
        localizedReason: 'Use sua digital ou rosto para entrar no app',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticação Biométrica',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(cancelButton: 'Cancelar'),
        ],
      );

      if (!autenticado || !mounted) return;

      // 2. Recupera credenciais salvas
      final String? email = await _secureStorage.read(key: 'bio_email');
      final String? senha = await _secureStorage.read(key: 'bio_senha');

      if (email == null || senha == null) {
        // Credenciais sumiram (ex: factory reset) — limpa flags e pede novo login
        await _limparCredenciaisBiometricas();
        _mostrarMensagem('Configure a biometria novamente fazendo login com e-mail e senha.');
        return;
      }

      // 3. Login real no Firebase
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = cred.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists || !mounted) {
        _mostrarMensagem('Usuário não encontrado.');
        return;
      }

      final nome = userDoc.data()?['nomeUsuario'] as String? ?? 'Usuário';
      await _salvarTokenENotificacoes(uid, nome);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_screen', arguments: nome);

    } on FirebaseAuthException catch (e) {
      // FIX: Firebase SDK v4+ unificou os códigos de credencial inválida.
      // 'wrong-password' e 'user-not-found' agora chegam como 'invalid-credential'
      // ou 'INVALID_LOGIN_CREDENTIALS'. Tratamos todos para garantir compatibilidade.
      final codigosCredencialInvalida = {
        'wrong-password',
        'user-not-found',
        'invalid-credential',
        'INVALID_LOGIN_CREDENTIALS',
      };

      if (codigosCredencialInvalida.contains(e.code)) {
        await _limparCredenciaisBiometricas();
        _mostrarMensagem(
          'Sua senha foi alterada. Faça login com e-mail e senha para reativar a biometria.',
        );
      } else if (e.code == 'network-request-failed') {
        _mostrarMensagem('Sem internet! Verifique sua conexão.');
      } else if (e.code == 'user-disabled') {
        _mostrarMensagem('Esta conta foi desativada. Entre em contato com o suporte.');
      } else {
        _mostrarMensagem(e.message ?? 'Erro ao autenticar. Tente fazer login manualmente.');
        debugPrint('⚠️ FirebaseAuthException não mapeada: ${e.code} — ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Erro no login biométrico: $e');
      _mostrarMensagem('Erro inesperado. Tente fazer login com e-mail e senha.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _limparCredenciaisBiometricas() async {
    await _secureStorage.delete(key: 'bio_email');
    await _secureStorage.delete(key: 'bio_senha');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('use_biometric');
  }

  // ─── Preferências ─────────────────────────────────────────────────────────

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lembrarLogin = prefs.getBool('lembrarLogin') ?? false;
      if (_lembrarLogin) {
        _emailController.text = prefs.getString('email_salvo') ?? '';
      }
    });
  }

  Future<void> _salvarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lembrarLogin) {
      await prefs.setString('email_salvo', _emailController.text.trim());
      await prefs.setBool('lembrarLogin', true);
    } else {
      await prefs.remove('email_salvo');
      await prefs.setBool('lembrarLogin', false);
    }
  }

  // ─── Fluxo pós-login ──────────────────────────────────────────────────────

  /// Padrão "app de banco": pergunta uma única vez se deseja ativar biometria.
  /// Só é exibido após login manual com e-mail e senha — nunca para Google.
  /// Salva as credenciais com segurança ANTES de navegar para home,
  /// assim o próximo acesso já terá a biometria disponível.
  Future<void> _checarCadastroBiometria(
      String nomeUsuario, String email, String senha) async {
    final prefs = await SharedPreferences.getInstance();

    final bool suporta = await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();

    // Exibe apenas se o dispositivo suporta E a preferência ainda não foi definida
    if (prefs.getBool('use_biometric') == null && suporta) {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Acesso Rápido',
            style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Deseja ativar a biometria (digital ou Face ID) para entrar sem digitar a senha nas próximas vezes?',
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await prefs.setBool('use_biometric', false);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Agora não',
                style: TextStyle(color: Colors.grey, fontFamily: 'Raleway'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
              onPressed: () async {
                // Salva as credenciais antes de navegar — garante disponibilidade
                // imediata na próxima abertura do app
                await _secureStorage.write(key: 'bio_email', value: email);
                await _secureStorage.write(key: 'bio_senha', value: senha);
                await prefs.setBool('use_biometric', true);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Ativar',
                style: TextStyle(color: Colors.white, fontFamily: 'Raleway'),
              ),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home_screen', arguments: nomeUsuario);
  }

  // ─── Autenticação ─────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Captura antes do await — evita uso de controller após dispose
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = cred.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuário não registrado no banco de dados.');
      }

      final nome = userDoc['nomeUsuario'] as String;
      await _salvarTokenENotificacoes(uid, nome);
      await _salvarPreferencias();

      // Oferece ativar biometria e só então navega para home
      await _checarCadastroBiometria(nome, email, senha);

    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'network-request-failed'
          ? 'Sem internet! Verifique sua conexão para fazer login.'
          : (e.message ?? 'Erro ao autenticar.');
      _mostrarMensagem(msg);
    } catch (e) {
      _mostrarMensagem('Ocorreu um erro inesperado.');
      debugPrint('❌ Erro no login: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Login com Google — não salva credenciais para biometria pois o token
  /// OAuth expira e não pode ser reusado para re-autenticar silenciosamente.
  /// A sessão Firebase persiste normalmente via AuthGate.
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // usuário cancelou

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid  = cred.user!.uid;
      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final doc = await docRef.get();
      final nome = googleUser.displayName ?? 'Usuário Google';

      if (!doc.exists) {
        await docRef.set({
          'nomeUsuario': nome,
          'email': googleUser.email,
          'dataCadastro': FieldValue.serverTimestamp(),
        });
      }

      await _salvarTokenENotificacoes(uid, nome);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_screen', arguments: nome);

    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'network-request-failed'
          ? 'Erro de rede. Verifique sua internet para conectar com o Google.'
          : 'Erro na autenticação com o Google.';
      _mostrarMensagem(msg);
    } catch (e) {
      _mostrarMensagem('Erro no login com Google.');
      debugPrint('❌ Erro Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _mostrarMensagem('Por favor, insira um e-mail válido para recuperar a senha.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _mostrarMensagem('E-mail de recuperação enviado com sucesso!');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found'        => 'Este e-mail não está cadastrado.',
        'network-request-failed' => 'Sem internet! Verifique sua conexão.',
        _                       => e.message ?? 'Erro ao enviar e-mail de recuperação.',
      };
      _mostrarMensagem(msg);
    } catch (e) {
      _mostrarMensagem('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Notificações ─────────────────────────────────────────────────────────

  Future<void> _salvarTokenENotificacoes(String uid, String nomeUsuario) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ Usuário recusou permissões de notificação.');
        return;
      }

      final token = await messaging
          .getToken()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .set({
        'fcmToken'       : token,
        'nomeUsuario'    : nomeUsuario,
        'isOnline'       : true,
        'ultimaAtividade': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM Token atualizado para: $nomeUsuario');
    } catch (e) {
      debugPrint('⚠️ Não foi possível atualizar o FCM Token: $e');
    }
  }

  // ─── Helpers de UI ────────────────────────────────────────────────────────

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon, bool isDark) {
    final contentColor = isDark ? Colors.white70 : Colors.black54;
    final primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: contentColor),
      floatingLabelStyle: TextStyle(color: primaryColor),
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final l10n         = AppLocalizations.of(context)!;
    final primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/PheliFlafundo.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.50)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A).withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 15,
                      offset: Offset(5, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.welcome,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 25),

                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputStyle('E-mail', Icons.email, isDark),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v != null && v.contains('@')) ? null : 'E-mail inválido',
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _senhaController,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        obscureText: !_mostrarSenha,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _isLoading ? null : _login(),
                        decoration:
                            _inputStyle('Senha', Icons.lock, isDark).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarSenha
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            onPressed: () =>
                                setState(() => _mostrarSenha = !_mostrarSenha),
                          ),
                        ),
                        validator: (v) =>
                            (v != null && v.length >= 6) ? null : 'Preencha a senha',
                      ),

                      Row(
                        children: [
                          Checkbox(
                            value: _lembrarLogin,
                            activeColor: Colors.red[900],
                            checkColor: Colors.white,
                            side: BorderSide(
                                color: isDark ? Colors.white70 : Colors.black54),
                            onChanged: (v) =>
                                setState(() => _lembrarLogin = v!),
                          ),
                          Text(
                            l10n.rememberEmail,
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _isLoading ? null : _recuperarSenha,
                            child: Text(
                              l10n.forgotYourPassword,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.blueAccent
                                    : Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                l10n.login,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('ou',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26)),
                        ],
                      ),
                      const SizedBox(height: 25),

                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: Icon(Icons.g_mobiledata,
                            size: 30,
                            color: isDark ? Colors.white : Colors.black87),
                        label: Text(
                          l10n.signInWithGoogle,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black26),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: Text(
                          l10n.dontHaveAnAccountSignUp,
                          style: TextStyle(
                            color: isDark ? Colors.redAccent : Colors.red[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog customizado de biometria ─────────────────────────────────────────

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fingerprint, size: 48, color: primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Acesso Biométrico',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Raleway',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use sua digital ou reconhecimento facial para entrar sem digitar a senha.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Raleway',
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: const Text(
                  'Usar Biometria',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
                child: Text(
                  'Usar e-mail e senha',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontFamily: 'Raleway',
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