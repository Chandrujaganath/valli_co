import 'package:flutter/material.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale;

  LocaleProvider({Locale locale = const Locale('en')}) : _locale = locale;

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'ta'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('en');
    notifyListeners();
  }
}
