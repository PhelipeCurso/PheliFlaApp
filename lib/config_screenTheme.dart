import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../locale_provider.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';
  final _auth = FirebaseAuth.instance;
  final _nomeController = TextEditingController();
  final _senhaController = TextEditingController();
  String _idiomaSelecionado = 'pt';
  bool _dadosCarregados = false;
  bool notificacoesAtivadas = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    carregarPreferencia();
  }

  void carregarPreferencia() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (mounted) {
        setState(() {
          notificacoesAtivadas = doc.data()?['notificacoesAtivadas'] ?? true;
        });
      }
    }
  }

  void atualizarPreferencia(bool valor) async {
    final uid = _auth.currentUser!.uid;
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'notificacoesAtivadas': valor,
    });
    setState(() {
      notificacoesAtivadas = valor;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosCarregados) {
      final user = _auth.currentUser;
      _nomeController.text = user?.displayName ?? '';
      _idiomaSelecionado = Localizations.localeOf(context).languageCode;
      _dadosCarregados = true;
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  // --- NOVA FUNÇÃO: EXCLUSÃO DE CONTA ---
  Future<void> _excluirConta() async {
    final s = AppLocalizations.of(context)!;
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      // 1. Deletar documento do usuário no Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).delete();

      // 2. Deletar o usuário no Firebase Auth
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sua conta e dados foram excluídos com sucesso.")),
        );
        // Redireciona para a tela inicial/login
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Para sua segurança, faça login novamente antes de excluir a conta.")),
          );
          await _auth.signOut();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir: ${e.message}")),
          );
        }
      }
    }
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Conta"),
        content: const Text("Tem certeza? Esta ação é permanente. Todas as suas mensagens e dados do PheliFla serão apagados para sempre."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirConta();
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _atualizarNome() async {
    try {
      await _auth.currentUser!.updateDisplayName(_nomeController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nameUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.nameUpdateError}: $e')),
        );
      }
    }
  }

  Future<void> _alterarSenha() async {
    try {
      await _auth.currentUser!.updatePassword(_senhaController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.passwordUpdateError}: $e')),
        );
      }
    }
  }

  void _mudarIdioma(String? idioma) {
    if (idioma == null) return;
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    provider.setLocale(Locale(idioma));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(s.darkMode),
            value: widget.isDarkMode,
            onChanged: widget.onThemeChanged,
          ),
          SwitchListTile(
            title: const Text("Notificações de novas mensagens"),
            value: notificacoesAtivadas,
            onChanged: atualizarPreferencia,
          ),
          const Divider(),
          TextField(
            controller: _nomeController,
            decoration: InputDecoration(labelText: s.username),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _atualizarNome, child: Text(s.updateName)),
          const SizedBox(height: 24),
          TextField(
            controller: _senhaController,
            decoration: InputDecoration(labelText: s.newPassword),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _alterarSenha,
            child: Text(s.changePassword),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _idiomaSelecionado,
            items: const [
              DropdownMenuItem(value: 'pt', child: Text('Português (Brasil)')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: _mudarIdioma,
            decoration: InputDecoration(labelText: s.language),
          ),
          const Divider(height: 40),
          
          // --- BOTÃO DE EXCLUSÃO ---
          ListTile(
            title: const Text("Excluir minha conta", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text("Remover permanentemente todos os seus dados"),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: _confirmarExclusao,
          ),
          
          const Divider(height: 40),
          ListTile(
            title: Text(s.appVersion),
            subtitle: Text(_version),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}