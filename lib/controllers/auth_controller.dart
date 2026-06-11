import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isDarkMode = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final userId = await _authService.getUserId();
      final name = await _authService.getUserName();
      final email = await _authService.getUserEmail();
      if (userId != null && name != null && email != null) {
        _currentUser = User(id: userId, name: name, email: email, password: '');
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (email.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir tous les champs';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _error = 'Email invalide';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _error = 'Le mot de passe doit contenir au moins 6 caractères';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final user = await _db.loginUser(email, password);
      if (user == null) {
        _error = 'Email ou mot de passe incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _currentUser = user;
      await _authService.saveSession(
        userId: user.id!,
        name: user.name,
        email: user.email,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password,
      String confirmPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'Veuillez remplir tous les champs';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _error = 'Email invalide';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _error = 'Le mot de passe doit contenir au moins 6 caractères';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _error = 'Les mots de passe ne correspondent pas';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        _error = 'Cet email est déjà utilisé';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = User(name: name, email: email, password: password);
      final id = await _db.registerUser(user);
      _currentUser = user.copyWith(id: id);
      await _authService.saveSession(
        userId: id,
        name: name,
        email: email,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint('Registration error: $e\n$stack');
      _error = 'Erreur lors de l\'inscription';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
