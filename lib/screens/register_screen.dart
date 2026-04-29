import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    // Validação inicial do Form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Criar usuário no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 2. Salvar dados extendidos no Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nomeUsuario': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'dataCadastro': FieldValue.serverTimestamp(),
        'status': 'ativo',
        'isOnline': true,
      });

      if (!mounted) return;

      // 3. Navegação Segura
      Navigator.pushReplacementNamed(
        context, 
        '/home_screen', 
        arguments: _nomeController.text.trim(),
      );

    } on FirebaseAuthException catch (e) {
      String erro = 'Erro ao registrar.';
      if (e.code == 'email-already-in-use') erro = 'Este e-mail já está cadastrado.';
      if (e.code == 'weak-password') erro = 'A senha é muito fraca.';
      
      _exibirAlerta(erro);
    } catch (e) {
      _exibirAlerta('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _exibirAlerta(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Mantendo sua identidade visual)
          Positioned.fill(
            child: Image.asset('assets/images/PheliFlafundo.png', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Crie sua conta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                      const SizedBox(height: 25),

                      _buildTextField(
                        controller: _nomeController,
                        label: 'Nome de Usuário',
                        icon: Icons.person_outline,
                        validator: (value) => value!.isEmpty ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 15),

                      _buildTextField(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => 
                            (value == null || !value.contains('@')) ? 'E-mail inválido' : null,
                      ),
                      const SizedBox(height: 15),

                      _buildPasswordField(
                        controller: _senhaController,
                        label: 'Senha',
                        visible: _mostrarSenha,
                        onToggle: () => setState(() => _mostrarSenha = !_mostrarSenha),
                        validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 15),

                      _buildPasswordField(
                        controller: _confirmarSenhaController,
                        label: 'Confirmar Senha',
                        visible: _mostrarConfirmarSenha,
                        onToggle: () => setState(() => _mostrarConfirmarSenha = !_mostrarConfirmarSenha),
                        validator: (value) {
                          if (value != _senhaController.text) return 'As senhas não coincidem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _registrarUsuario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[900],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Text('CADASTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Já tem conta? Fazer login',
                          style: TextStyle(color: Colors.red[900]),
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

  // Widget auxiliar para campos de texto comuns
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  // Widget auxiliar para campos de senha
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}