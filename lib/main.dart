import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pheli_fla_app/widgets/prefs_service.dart';
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

// Notificações
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/service_notifications.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Permissões e Handler de Background
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializa serviço de notificações
  await NotificationService.init(); 

  // Busca as preferências persistidas
  bool isDark = await PrefsService.getTheme();
  String lang = await PrefsService.getLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(Locale(lang))),
        ChangeNotifierProvider(create: (_) => UserPlusProvider()),
      ],
      child: MyApp(isDark: isDark),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isDark;
  const MyApp({super.key, required this.isDark});

  @override
  State<MyApp> createState() => _MyAppState();

  // Método estático para encontrar o estado do MyApp em qualquer lugar (útil para trocar tema)
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
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
    // 1. INSCRIÇÃO NOS TÓPICOS GERAIS
    await FirebaseMessaging.instance.subscribeToTopic('placar_notificacoes');
    await FirebaseMessaging.instance.subscribeToTopic('noticias');
    
    // IMPORTANTE: Para o chat funcionar fora da sala, o usuário precisa estar 
    // inscrito no tópico da sala específica (ex: 'sala_geral').
    // Você pode adicionar isso aqui ou na tela onde ele escolhe a sala.
    // await FirebaseMessaging.instance.subscribeToTopic('nome_da_sala_aqui');

    print("✅ Inscrito nos tópicos gerais");

    // 2. CONFIGURAÇÃO DE PRIORIDADE (Android)
    // Isso garante que o sistema operacional saiba como exibir o alerta
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // 1. Pega os IDs para comparação
  final String? senderId = message.data['senderId']?.toString();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // 2. Pega os textos que agora estão dentro de 'data'
  final String? tituloCustom = message.data['titulo'];
  final String? corpoCustom = message.data['corpo'];

  // 3. LOG para você conferir no console se os IDs estão batendo
  print("🔔 Notificação via Data: Remetente $senderId | Eu: $currentUserId");

  // 4. FILTRO DE AUTO-NOTIFICAÇÃO
  if (senderId != null && currentUserId != null && senderId == currentUserId) {
    print("🚫 Ignorando: Eu sou o remetente.");
    return; // Mata a execução aqui
  }

  // 5. DISPARA A NOTIFICAÇÃO LOCAL (Apenas se houver dados e não for eu mesmo)
  if (tituloCustom != null && corpoCustom != null) {
    NotificationService.showNotification(
      tituloCustom,
      corpoCustom,
    );
  }
});
    
    // 4. TRATAMENTO DE CLIQUE NA NOTIFICAÇÃO (App em Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       print("Usuário clicou na notificação!");
       // Aqui você pode usar o Navigator para levar o usuário direto para a sala
       // baseando-se no message.data['roomName']
    });
  }

  // Função para alternar o tema e salvar
  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    PrefsService.saveTheme(isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
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
          initialRoute: '/login',
          routes: _buildRoutes(),
        );
      },
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (context) => const LoginScreen(),
      '/register': (context) => const RegisterScreen(),
      '/room-selection': (context) => const RoomSelectionScreen(),
      '/loja-selection': (context) => const EscolhaLojaScreen(),
      '/loja': (context) {
        final loja = ModalRoute.of(context)!.settings.arguments as String;
        return LojaScreen(Loja: loja);
      },
      '/home_screen': (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        final nomeUsuario = args is String ? args : "Usuário";
        
        return Consumer<UserPlusProvider>(
          builder: (context, plusProvider, _) {
            plusProvider.checkPlusStatus();
            return HomeScreen(
              nomeUsuario: nomeUsuario,
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: toggleTheme,
              isPlusUser: plusProvider.isPlus,
            );
          },
        );
      },
    };
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      fontFamily: 'Raleway',
      brightness: brightness,
      primaryColor: Colors.red[900],
      // No Dark Mode o cardColor é cinza escuro, no Light é branco.
      cardColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      scaffoldBackgroundColor: brightness == Brightness.dark ? Colors.black : const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}