import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pheli_fla_app/widgets/prefs_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/room_selection_screen.dart';
import 'screens/loja_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pheli_fla_app/locale_provider.dart';
import 'pages/noticias_page_coluna.dart';
import 'screens/escolha_loja_screen.dart';
import 'providers/user_plus_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/minigames/bolao_screen.dart';
import 'screens/minigames/quiz_screen.dart';
import 'screens/minigames/ranking_screen.dart';


// Biometria
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

// Notificações
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/service_notifications.dart';

// ─── Background handler (deve ser top-level) ──────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// ─── Entry point ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Persistência offline do Realtime Database (ignora erro se já inicializado)
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (e) {
    debugPrint('⚠️ Persistência já habilitada: $e');
  }

  // Inicializações secundárias em paralelo — falhas individuais não bloqueiam o app
  await Future.wait([
    MobileAds.instance.initialize(),
    FirebaseMessaging.instance.requestPermission(),
    NotificationService.init(),
  ]).catchError((e) {
    debugPrint('⚠️ Falha em inicialização secundária: $e');
    return <void>[];
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final isDark = await PrefsService.getTheme();
  final lang = await PrefsService.getLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..setLocale(Locale(lang)),
        ),
        ChangeNotifierProvider(create: (_) => UserPlusProvider()),
      ],
      child: MyApp(isDark: isDark),
    ),
  );
}

// ─── App root ─────────────────────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  final bool isDark;
  const MyApp({super.key, required this.isDark});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDark ? ThemeMode.dark : ThemeMode.light;
    _setupFCM();
  }

  void _setupFCM() async {
    await FirebaseMessaging.instance.subscribeToTopic('placar_notificacoes');
    await FirebaseMessaging.instance.subscribeToTopic('noticias');

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final senderId = message.data['senderId']?.toString();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // Não exibe notificação para mensagens enviadas pelo próprio usuário
      if (senderId != null && senderId == currentUserId) return;

      final titulo = message.data['titulo'] as String?;
      final corpo = message.data['corpo'] as String?;

      if (titulo != null && corpo != null) {
        NotificationService.showNotification(titulo, corpo);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      debugPrint('📲 Usuário abriu o app via notificação.');
    });
  }

  void toggleTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    PrefsService.saveTheme(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return MaterialApp(
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          title: 'Flamengo Chat',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: _themeMode,
          initialRoute: '/',
          routes: _buildRoutes(),
        );
      },
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (_) => const AuthGate(),
      '/login': (_) => const LoginScreen(),
      '/register': (_) => const RegisterScreen(),
      '/room-selection': (_) => const RoomSelectionScreen(),
      '/loja-selection': (_) => const EscolhaLojaScreen(),
      '/bolao': (context) => const BolaoScreen(),
      '/quiz': (context) => const QuizScreen(),
      '/ranking_screen': (context) => const RankingScreen(),
      '/loja': (context) {
        final loja =
            ModalRoute.of(context)!.settings.arguments as String;
        return LojaScreen(Loja: loja);
      },
      '/home_screen': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        final nomeUsuario = args is String ? args : 'Usuário';

        return Consumer<UserPlusProvider>(
          builder: (context, plusProvider, _) {
            plusProvider.checkPlusStatus();
            return HomeScreen(
              nomeUsuario: nomeUsuario,
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: toggleTheme,
              isPlusUser: plusProvider.isPlus ?? false,
            );
          },
        );
      },
    };
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      fontFamily: 'Raleway',
      brightness: brightness,
      primaryColor: Colors.red[900],
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      scaffoldBackgroundColor:
          isDark ? Colors.black : const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────

/// Decide para onde o usuário deve ser direcionado ao abrir o app:
/// - Sem sessão → LoginScreen
/// - Com sessão + biometria ativada → BiometricLock
/// - Com sessão sem biometria → HomeScreen diretamente
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_biometric') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Aguardando estado de autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingScreen();
        }

        // Usuário com sessão ativa
        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: _isBiometricEnabled(),
            builder: (context, bioSnapshot) {
              if (bioSnapshot.connectionState == ConnectionState.waiting) {
                return _LoadingScreen();
              }

              // Biometria ativada → tela de bloqueio
              if (bioSnapshot.data == true) {
                return BiometricLock(user: snapshot.data!);
              }

              // Sem biometria → redireciona direto para Home
              return _DirectHomeRedirect(user: snapshot.data!);
            },
          );
        }

        // Sem sessão → tela de login
        return const LoginScreen();
      },
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
          child: CircularProgressIndicator(color: Colors.red[900])),
    );
  }
}

/// Redireciona para a Home após o primeiro frame, evitando conflito de rotas
/// durante o build do StreamBuilder.
class _DirectHomeRedirect extends StatefulWidget {
  final User user;
  const _DirectHomeRedirect({required this.user});

  @override
  State<_DirectHomeRedirect> createState() => _DirectHomeRedirectState();
}

class _DirectHomeRedirectState extends State<_DirectHomeRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home_screen',
        // Prioriza displayName (Google); usa 'Nação' como fallback
        arguments: widget.user.displayName?.isNotEmpty == true
            ? widget.user.displayName
            : 'Nação',
      );
    });
  }

  @override
  Widget build(BuildContext context) => _LoadingScreen();
}

// ─── Tela de bloqueio biométrico ──────────────────────────────────────────────

/// Exibida quando o usuário tem sessão ativa e ativou a biometria.
/// Autentica e navega para Home, ou permite sair da conta.
class BiometricLock extends StatefulWidget {
  final User user;
  const BiometricLock({super.key, required this.user});

  @override
  State<BiometricLock> createState() => _BiometricLockState();
}

class _BiometricLockState extends State<BiometricLock> {
  final _auth = LocalAuthentication();

  bool _isAuthenticating = false;
  String _mensagem = 'Use a biometria para entrar';

  @override
  void initState() {
    super.initState();
    // Dispara o prompt biométrico automaticamente ao montar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) => _autenticar());
  }

  Future<void> _autenticar() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _mensagem = 'Autenticando...';
    });

    try {
      final bool autenticado = await _auth.authenticate(
        localizedReason: 'Desbloqueie para acessar o PheliFla',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticação Biométrica',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(cancelButton: 'Cancelar'),
        ],
      );

      if (!mounted) return;

      if (autenticado) {
        final nome = widget.user.displayName?.isNotEmpty == true
            ? widget.user.displayName!
            : 'Nação';
        Navigator.pushReplacementNamed(
          context,
          '/home_screen',
          arguments: nome,
        );
      } else {
        setState(() {
          _isAuthenticating = false;
          _mensagem = 'Falha na autenticação. Tente novamente.';
        });
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Erro de biometria: $e');
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _mensagem = 'Biometria indisponível ou não configurada.';
      });
    }
  }

  Future<void> _sairDaConta() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, size: 80, color: Colors.red[900]),
              const SizedBox(height: 20),
              Text(
                _mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 30),
              if (!_isAuthenticating) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _autenticar,
                  child: const Text(
                    'Tentar Novamente',
                    style: TextStyle(
                        color: Colors.white, fontFamily: 'Raleway'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _sairDaConta,
                  child: const Text(
                    'Sair da conta',
                    style:
                        TextStyle(color: Colors.grey, fontFamily: 'Raleway'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}