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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

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
      'isOnline': true,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/PheliFlafundo.png', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(isDark ? 0.50 : 0.50)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A).withOpacity(0.75) : Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 15, offset: const Offset(5, 5)),
                  ],
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
                          color: isDark ? Colors.redAccent : Colors.red[900],
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputStyle("E-mail", Icons.email, isDark),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.contains('@') ? null : "E-mail inválido",
                      ),
                      
                      const SizedBox(height: 15),
                      
                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_mostrarSenha,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputStyle("Senha", Icons.lock, isDark).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarSenha ? Icons.visibility : Icons.visibility_off,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
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
                            checkColor: Colors.white,
                            side: BorderSide(color: isDark ? Colors.white70 : Colors.black54),
                            onChanged: (v) => setState(() => _lembrarLogin = v!),
                          ),
                          Text(
                            "Lembrar e-mail",
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Esqueceu a senha?",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.blueAccent : Colors.blue[800],
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("ENTRAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black26)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("ou", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black26)),
                        ],
                      ),

                      const SizedBox(height: 25),

                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        icon: Icon(Icons.g_mobiledata, size: 30, color: isDark ? Colors.white : Colors.black87),
                        label: Text(
                          "Entrar com Google",
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: isDark ? Colors.white38 : Colors.black26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          "Não tem conta? Cadastre-se",
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

  // MÉTODO DE ESTILO ÚNICO E CORRIGIDO
  InputDecoration _inputStyle(String label, IconData icon, bool isDark) {
    final Color contentColor = isDark ? Colors.white70 : Colors.black54;
    final Color primaryColor = isDark ? Colors.redAccent : Colors.red[900]!;

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
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
    );
  }
}