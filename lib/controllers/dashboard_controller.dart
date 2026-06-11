import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DashboardController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalTasks => _stats?['total'] ?? 0;
  int get todoTasks => _stats?['todo'] ?? 0;
  int get inProgressTasks => _stats?['inProgress'] ?? 0;
  int get doneTasks => _stats?['done'] ?? 0;
  double get completionRate =>
      totalTasks > 0 ? (doneTasks / totalTasks) * 100 : 0;
  List<dynamic> get priorityCounts => _stats?['priorityCounts'] ?? [];
  List<dynamic> get categoryCounts => _stats?['categoryCounts'] ?? [];

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await _db.getDashboardStats();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des statistiques';
    }

    _isLoading = false;
    notifyListeners();
  }
}
