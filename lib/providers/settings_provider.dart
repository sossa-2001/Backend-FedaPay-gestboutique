import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SyncService _sync;
  String _companyName = 'Gest-Boutique';
  bool _isDarkMode = false;
  bool _loaded = false;
  String? _logoBase64;

  SettingsProvider(this._db, this._sync);

  String get companyName => _companyName;
  bool get isDarkMode => _isDarkMode;
  bool get loaded => _loaded;
  String? get logoBase64 => _logoBase64;

  Future<void> load() async {
    final name = await _db.getSetting('companyName');
    if (name != null && name.isNotEmpty) {
      _companyName = name;
    }
    final dark = await _db.getSetting('isDarkMode');
    if (dark != null) {
      _isDarkMode = dark == 'true';
    }
    final logo = await _db.getSetting('logoBase64');
    if (logo != null && logo.isNotEmpty) {
      _logoBase64 = logo;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCompanyName(String name) async {
    _companyName = name;
    notifyListeners();
    try {
      await _db.setSetting('companyName', name);
      _sync.syncSettings({
        'companyName': name,
        'isDarkMode': _isDarkMode.toString(),
        if (_logoBase64 != null) 'logoBase64': _logoBase64!,
      });
    } catch (_) {}
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      await _db.setSetting('isDarkMode', _isDarkMode.toString());
      _sync.syncSettings({
        'companyName': _companyName,
        'isDarkMode': _isDarkMode.toString(),
        if (_logoBase64 != null) 'logoBase64': _logoBase64!,
      });
    } catch (_) {
      debugPrint('Erreur sauvegarde thème');
    }
  }

  Future<void> pickLogo() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      _logoBase64 = base64Encode(bytes);
      notifyListeners();
      await _db.setSetting('logoBase64', _logoBase64!);
      _sync.syncSettings({
        'companyName': _companyName,
        'isDarkMode': _isDarkMode.toString(),
        'logoBase64': _logoBase64!,
      });
    } catch (_) {
      debugPrint('Erreur lors de la sélection du logo');
    }
  }

  Future<void> removeLogo() async {
    _logoBase64 = null;
    notifyListeners();
    try {
      await _db.setSetting('logoBase64', '');
      _sync.syncSettings({
        'companyName': _companyName,
        'isDarkMode': _isDarkMode.toString(),
        'logoBase64': '',
      });
    } catch (_) {}
  }
}
