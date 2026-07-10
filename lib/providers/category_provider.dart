import 'package:flutter/material.dart';
import '../models/category.dart';
import '../data/database_service.dart';
import '../services/sync_service.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _db;
  final SyncService _sync;
  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryProvider(this._db, this._sync);

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _db.loadCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _db.addCategory(category);
    _sync.syncCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _db.updateCategory(category);
    _sync.syncCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    _sync.deleteCategory(id);
    await loadCategories();
  }

  int getCategoryCount() => _categories.length;
}
