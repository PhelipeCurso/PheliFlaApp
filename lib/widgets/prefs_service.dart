import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _themeKey = 'isDarkMode';
  static const _langKey = 'languageCode';

  // Salva o tema
  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  // Busca o tema (padrão false)
  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  // Salva o idioma
  static Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
  }

  // Busca o idioma (padrão 'pt')
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'pt';
  }
}