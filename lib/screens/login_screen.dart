import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Autentica o usuário
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      // 2. Busca o nome de usuário no Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();

      if (!userDoc.exists ||
          !(userDoc.data() as Map).containsKey('nomeUsuario')) {
        setState(() => _errorMessage = 'Nome de usuário não encontrado.');
        return;
      }

      final nomeUsuario = userDoc['nomeUsuario'];
      // ⬇️ Salva token e preferências
      await salvarTokenENotificacoes(uid, nomeUsuario);

      // Navega para a próxima tela
      Navigator.pushReplacementNamed(
        context,
        '/room-selection',
        arguments: nomeUsuario,
      );

      // 3. Vai para a seleção de sala e passa o nome
      Navigator.pushReplacementNamed(
        context,
        '/room-selection',
        arguments: nomeUsuario,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Erro: ${e.message}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // Usuário cancelou o login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final uid = userCredential.user!.uid;

      // Verifica se já existe no Firestore, senão cria
      final userDocRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);

      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'nomeUsuario': googleUser.displayName ?? 'Usuário Google',
          'email': googleUser.email,
        });
      }
      await salvarTokenENotificacoes(
        uid,
        googleUser.displayName ?? 'Usuário Google',
      );

      Navigator.pushReplacementNamed(
        context,
        '/home_screen',
        arguments: googleUser.displayName ?? 'Usuário Google',
      );
    } catch (e) {
      setState(() => _errorMessage = 'Erro no login com Google: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> salvarTokenENotificacoes(String uid, String nomeUsuario) async {
    final token = await FirebaseMessaging.instance.getToken();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'fcmToken': token,
      'notificacoesAtivadas': true, // Ativa por padrão
      'nomeUsuario': nomeUsuario,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/PheliFlafundo.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _emailController,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 17, 17, 17),
                      ), // Cor do texto
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 15, 15, 15),
                        ), // Cor do label
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 19, 18, 18),
                          ), // Cor da linha
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Entrar',
                                style: const TextStyle(color: Colors.white),
                              ),
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Entrar com Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'Não tem conta? Cadastre-se',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
