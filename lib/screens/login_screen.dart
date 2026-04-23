import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarSenha = false;
  bool _lembrarLogin = false;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Segurança: Salva apenas o e-mail, nunca a senha.
  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

      final uid = userCredential.user!.uid;
      
      // Busca dados adicionais
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios').doc(uid).get();

      if (!userDoc.exists) throw "Usuário não registrado no banco de dados.";

      final nomeUsuario = userDoc['nomeUsuario'];
      await _salvarTokenENotificacoes(uid, nomeUsuario);
      await _salvarPreferencias();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_screen', arguments: nomeUsuario);
      
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(e.message ?? "Erro ao autenticar.");
    } catch (e) {
      _mostrarMensagem("Ocorreu um erro inesperado.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // Verifica ou cria perfil no Firestore
      final userDocRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final doc = await userDocRef.get();

      String nome = googleUser.displayName ?? 'Usuário Google';
      if (!doc.exists) {
        await userDocRef.set({
          'nomeUsuario': nome,
          'email': googleUser.email,
          'dataCadastro': FieldValue.serverTimestamp(),
        });
      }

      await _salvarTokenENotificacoes(uid, nome);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_screen', arguments: nome);
    } catch (e) {
      _mostrarMensagem("Erro no login com Google.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarTokenENotificacoes(String uid, String nomeUsuario) async {
    final token = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'fcmToken': token,
      'nomeUsuario': nomeUsuario,
      'ultimaAtividade': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset('assets/images/PheliFlafundo.png', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Bem-vindo!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputStyle("E-mail", Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.contains('@') ? null : "E-mail inválido",
                      ),
                      
                      const SizedBox(height: 15),
                      
                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_mostrarSenha,
                        decoration: _inputStyle("Senha", Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_mostrarSenha ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                          ),
                        ),
                        validator: (value) => value!.length < 6 ? "Preencha a senha" : null,
                      ),

                      Row(
                        children: [
                          Checkbox(
                            value: _lembrarLogin,
                            activeColor: Colors.red[900],
                            onChanged: (v) => setState(() => _lembrarLogin = v!),
                          ),
                          const Text("Lembrar e-mail"),
                          const Spacer(),
                          TextButton(
                            onPressed: () {}, // Adicionar recuperação de senha aqui
                            child: const Text("Esqueceu a senha?", style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("ENTRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("ou")),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text("Entrar com Google"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text("Não tem conta? Cadastre-se", style: TextStyle(color: Colors.red)),
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

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}