import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pheli_fla_app/config_screenTheme.dart';
import 'package:pheli_fla_app/gen_l10n/app_localizations.dart';
import 'package:pheli_fla_app/pages/agenda_rubro_negra_page.dart';
import 'package:pheli_fla_app/screens/assinatura_plus_screen.dart';
import 'package:pheli_fla_app/screens/cantos_list_screen.dart';
import 'package:pheli_fla_app/screens/escolha_loja_screen.dart';
import 'package:pheli_fla_app/constants/app_constants.dart';

class CustomDrawer extends StatelessWidget {
  final User? user;
  final String nomeUsuario;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onLogout;
  final Future<void> Function() onTicketsTap;

  const CustomDrawer({
    Key? key,
    required this.user,
    required this.nomeUsuario,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLogout,
    required this.onTicketsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryRed),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : const AssetImage('assets/images/Gaming.png')
                          as ImageProvider,
            ),
            accountName: Text(
              nomeUsuario,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? ''),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(
                  context,
                  icon: AppIcons.home,
                  title: localizations.home,
                  onTap: () => Navigator.pop(context),
                ),
                _buildListTile(
                  context,
                  icon: AppIcons.chat,
                  title: localizations.chat,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/room-selection',
                      arguments: nomeUsuario,
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: AppIcons.agenda,
                  title: localizations.agendaTitle,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AgendaRubroNegraPage()),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: AppIcons.hymns,
                  title: localizations.menuHymns,
                  iconColor: AppColors.primaryRed,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CantosListScreen(),
                      ),
                    );
                  },
                ),
                ExpansionTile(
                  leading: Icon(AppIcons.games, color: AppColors.gold),
                  title: const Text(
                    'Games',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  iconColor: AppColors.primaryRed,
                  collapsedIconColor: AppColors.subtitleGrey,
                  childrenPadding: const EdgeInsets.only(left: 15),
                  children: [
                    _buildListTile(
                      context,
                      icon: AppIcons.bolao,
                      title: 'Bolão PheliFla',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/bolao');
                      },
                    ),
                    _buildListTile(
                      context,
                      icon: AppIcons.quiz,
                      title: 'Quiz Diário',
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/quiz');
                      },
                    ),
                  ],
                ),
                _buildListTile(
                  context,
                  icon: AppIcons.store,
                  title: localizations.store,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EscolhaLojaScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  icon: AppIcons.ticket,
                  title: localizations.ticket,
                  subtitle: localizations.buyTicketsForTheGames,
                  iconColor: AppColors.primaryRed,
                  onTap: () {
                    Navigator.pop(context);
                    onTicketsTap();
                  },
                ),
                _buildListTile(
                  context,
                  icon: AppIcons.subscribe,
                  title: localizations.subscribeNow,
                  iconColor: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssinaturaPlusScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildListTile(
                  context,
                  icon: AppIcons.settings,
                  title: localizations.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SettingsScreen(
                              isDarkMode: isDarkMode,
                              onThemeChanged: onThemeChanged,
                            ),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildListTile(
                  context,
                  icon: AppIcons.logout,
                  title: localizations.logout,
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.menuIcon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }
}
