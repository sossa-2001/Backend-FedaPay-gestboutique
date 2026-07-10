import 'package:flutter/material.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SyncService _sync;
  String _companyName = 'Gest-Boutique';
  bool _isDarkMode = false;
  bool _loaded = false;

  SettingsProvider(this._db, this._sync);

  String get companyName => _companyName;
  bool get isDarkMode => _isDarkMode;
  bool get loaded => _loaded;

  Future<void> load() async {
    final name = await _db.getSetting('companyName');
    if (name != null && name.isNotEmpty) {
      _companyName = name;
    }
    final dark = await _db.getSetting('isDarkMode');
    if (dark != null) {
      _isDarkMode = dark == 'true';
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCompanyName(String name) async {
    _companyName = name;
    await _db.setSetting('companyName', name);
    _sync.syncSettings({
      'companyName': name,
      'isDarkMode': _isDarkMode.toString(),
    });
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      await _db.setSetting('isDarkMode', _isDarkMode.toString());
      _sync.syncSettings({
        'companyName': _companyName,
        'isDarkMode': _isDarkMode.toString(),
      });
    } catch (_) {
      debugPrint('Erreur sauvegarde thème');
    }
  }
}
