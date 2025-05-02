import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../locale_provider.dart'; // Ajuste o caminho conforme seu projeto

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

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Carregar dados dependentes de contexto apenas uma vez
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

  Future<void> _atualizarNome() async {
    try {
      await _auth.currentUser!.updateDisplayName(_nomeController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nameUpdatedSuccess)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.nameUpdateError}: $e')),
      );
    }
  }

  Future<void> _alterarSenha() async {
    try {
      await _auth.currentUser!.updatePassword(_senhaController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccess)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.passwordUpdateError}: $e')),
      );
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
          const Divider(),
          TextField(
            controller: _nomeController,
            decoration: InputDecoration(labelText: s.username),
          ),
          ElevatedButton(
            onPressed: _atualizarNome,
            child: Text(s.updateName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senhaController,
            decoration: InputDecoration(labelText: s.newPassword),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: _alterarSenha,
            child: Text(s.changePassword),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _idiomaSelecionado,
            items: const [
              DropdownMenuItem(value: 'pt', child: Text('Português (Brasil)')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: _mudarIdioma,
            decoration: InputDecoration(labelText: s.language),
          ),
          const Divider(height: 32),
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
