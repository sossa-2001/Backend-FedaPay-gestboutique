import 'package:flutter/material.dart';
import '../data/database_service.dart';

class LocaleProvider extends ChangeNotifier {
  final DatabaseService _db;
  Locale _locale = const Locale('fr');

  LocaleProvider(this._db);

  Locale get locale => _locale;

  Future<void> load() async {
    final code = await _db.getSetting('locale');
    if (code != null && ['en', 'fr'].contains(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    try {
      await _db.setSetting('locale', locale.languageCode);
    } catch (_) {}
  }
}
