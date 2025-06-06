import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pheli_fla_app/providers/user_plus_provider.dart';

class AssinaturaPlusScreen extends StatelessWidget {
  const AssinaturaPlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.assinaturaPlus),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.bemVindoAoPlus,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.descricaoAssinaturaPlus,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    _beneficioItem(
                      icon: Icons.block,
                      title: localizations.semAnuncios,
                      context: context,
                    ),
                    _beneficioItem(
                      icon: Icons.lock_clock,
                      title: localizations.acessoAntecipadoNoticias,
                      context: context,
                    ),
                    _beneficioItem(
                      icon: Icons.chat,
                      title: localizations.chatExclusivo,
                      context: context,
                    ),
                    _beneficioItem(
                      icon: Icons.support,
                      title: localizations.ajudeProjeto,
                      context: context,
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Integrar com sistema de pagamento
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(localizations.assinaturaEmBreve),
                            ),
                          );
                        },
                        icon: const Icon(Icons.attach_money),
                        label: Text(localizations.assinarAgora),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: Abrir termos de uso
                        },
                        child: Text(localizations.termosAssinatura),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _beneficioItem({
    required IconData icon,
    required String title,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
