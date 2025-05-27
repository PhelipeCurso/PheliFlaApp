import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/room_selection_screen.dart';
import 'screens/loja_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pheli_fla_app/locale_provider.dart';
import 'pages/noticias_page_coluna.dart';
import 'screens/escolha_loja_screen.dart';

// Notificações
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/service_notifications.dart'; // <-- Certifique-se de criar e importar

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensagem em segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService.init(); // Inicializa notificações locais

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

    // Escuta mensagens quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.showNotification(
          notification.title ?? 'Nova Mensagem',
          notification.body ?? '',
        );
      }
    });
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
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
            theme: ThemeData(
              fontFamily: 'Raleway',
              primaryColor: Colors.red[900],
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
              ),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              fontFamily: 'Raleway',
              brightness: Brightness.dark,
              primaryColor: Colors.red[900],
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
              ),
            ),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/room-selection': (context) => const RoomSelectionScreen(),
              '/loja-selection': (context) => const EscolhaLojaScreen(),
              '/loja': (context) {
                final Loja =
                    ModalRoute.of(context)!.settings.arguments as String;
                return LojaScreen(Loja: Loja);
              },
              '/home_screen': (context) {
                final nomeUsuario =
                    ModalRoute.of(context)!.settings.arguments as String;
                return HomeScreen(
                  nomeUsuario: nomeUsuario,
                  isDarkMode: isDarkMode,
                  onThemeChanged: toggleTheme,
                );
              },
            },
          );
        },
      ),
    );
  }
}
