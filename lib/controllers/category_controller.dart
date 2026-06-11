import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _db.getCategories();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des catégories';
    }

    _isLoading = false;
    notifyListeners();
  }

  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createCategory(Category category) async {
    try {
      final id = await _db.insertCategory(category);
      _categories.add(category.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la création';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await _db.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _db.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression';
      notifyListeners();
      return false;
    }
  }
}
