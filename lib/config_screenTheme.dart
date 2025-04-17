import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _version = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo escuro'),
            value: widget.isDarkMode,
            onChanged: widget.onThemeChanged,
          ),
          const Divider(),
          ListTile(
            title: const Text('Versão do app'),
            subtitle: Text(_version),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
