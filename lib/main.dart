import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/room_selection_screen.dart';
import 'screens/loja_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FlamengoChatApp());
}

class FlamengoChatApp extends StatefulWidget {
  const FlamengoChatApp({super.key});

  @override
  State<FlamengoChatApp> createState() => _FlamengoChatAppState();
}

class _FlamengoChatAppState extends State<FlamengoChatApp> {
  bool isDarkMode = false;

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/room-selection': (context) {
          final nomeUsuario =
              ModalRoute.of(context)!.settings.arguments as String;
          return RoomSelectionScreen(); // já usamos os argumentos no widget via ModalRoute
        }, //'/room-selection': (context) => const RoomSelectionScreen(),
        '/loja': (context) => const LojaScreen(),
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
  }
}
