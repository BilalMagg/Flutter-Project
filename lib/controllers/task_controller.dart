import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class TaskController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all';
  int? _categoryFilter;
  String _sortBy = 'createdAt';

  List<Task> get tasks => _filteredTasks;
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  int? get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _db.getTasks();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des tâches';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Task?> getTaskById(int id) async {
    return await _db.getTaskById(id);
  }

  Future<bool> createTask(Task task) async {
    try {
      final id = await _db.insertTask(task);
      await _api.createTask(task);
      final newTask = task.copyWith(id: id);
      _tasks.insert(0, newTask);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la création';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await _db.updateTask(task);
      await _api.updateTaskRemote(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _db.deleteTask(id);
      await _api.deleteTaskRemote(id);
      _tasks.removeWhere((t) => t.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTaskStatus(Task task) async {
    final newStatus = task.status == 'done' ? 'todo' : 'done';
    return await updateTask(task.copyWith(status: newStatus));
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _categoryFilter = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTasks = List.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      _filteredTasks = _filteredTasks
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_statusFilter != 'all') {
      _filteredTasks =
          _filteredTasks.where((t) => t.status == _statusFilter).toList();
    }

    if (_categoryFilter != null) {
      _filteredTasks =
          _filteredTasks.where((t) => t.categoryId == _categoryFilter).toList();
    }

    switch (_sortBy) {
      case 'priority':
        _filteredTasks.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'dueDate':
        _filteredTasks.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'title':
        _filteredTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      default:
        _filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }
}
