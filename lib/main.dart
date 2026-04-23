import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

// Handler para mensagens em segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Solicita permissão e configura o handler de background
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? token = await FirebaseMessaging.instance.getToken();
  print("========================================");
  print("MEU TOKEN DE DISPOSITIVO:");
  print(token); // Copie este código que aparecerá no seu console (Debug Console)
  print("========================================");

  // 3. Configura o handler de segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



  // Inicializa o serviço que agora também inscreve nos tópicos
  await NotificationService.init(); 

  runApp(const FlamengoChatApp());
}

class FlamengoChatApp extends StatefulWidget {
  const FlamengoChatApp({super.key});

  @override
  State<FlamengoChatApp> createState() => _FlamengoChatAppState();
}

class _FlamengoChatAppState extends State<FlamengoChatApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();

    // Ouvindo mensagens com o APP ABERTO
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationService.showNotification(
          message.notification!.title ?? 'PheliFla Avisa:',
          message.notification!.body ?? '',
        );
      }
    });
  }

  void toggleTheme(bool value) {
    setState(() => isDarkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserPlusProvider()),
      ],
      child: Consumer<LocaleProvider>(
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
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/login',
            routes: _buildRoutes(),
          );
        },
      ),
    );
  }

  // Organização das Rotas
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
        final nomeUsuario = ModalRoute.of(context)!.settings.arguments as String;
        return Consumer<UserPlusProvider>(
          builder: (context, plusProvider, _) {
            // Verifica status Plus ao entrar
            plusProvider.checkPlusStatus();
            return HomeScreen(
              nomeUsuario: nomeUsuario,
              isDarkMode: isDarkMode,
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
      scaffoldBackgroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}
