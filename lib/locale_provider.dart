import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (!L10n.supportedLocales.contains(newLocale)) return;

    _locale = newLocale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('pt');
    notifyListeners();
  }
}

class L10n {
  static const supportedLocales = [
    Locale('en'),
    Locale('pt'),
  ];

  static const localeNames = {
    'en': 'English',
    'pt': 'Português (Brasil)',
  };
}
