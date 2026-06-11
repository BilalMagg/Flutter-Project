import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  final http.Client _client = http.Client();
  bool _useMock = true;

  void setUseMock(bool value) {
    _useMock = value;
  }

  Future<List<Task>> fetchTasks() async {
    if (_useMock) return _mockFetchTasks();
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/todos'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch tasks');
    } catch (e) {
      return _mockFetchTasks();
    }
  }

  Future<Task> createTask(Task task) async {
    if (_useMock) return _mockCreateTask(task);
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/todos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(task.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to create task');
    } catch (e) {
      return _mockCreateTask(task);
    }
  }

  Future<Task> updateTaskRemote(Task task) async {
    if (_useMock) return _mockUpdateTask(task);
    try {
      final response = await _client
          .put(
            Uri.parse('$_baseUrl/todos/${task.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(task.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to update task');
    } catch (e) {
      return _mockUpdateTask(task);
    }
  }

  Future<bool> deleteTaskRemote(int id) async {
    if (_useMock) return _mockDeleteTask(id);
    try {
      final response = await _client
          .delete(Uri.parse('$_baseUrl/todos/$id'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return _mockDeleteTask(id);
    }
  }

  List<Task> _mockFetchTasks() {
    final random = Random();
    return List.generate(
      10,
      (i) => Task(
        id: i + 1,
        title: _mockTitles[i],
        description: 'Description de la tâche ${i + 1}',
        priority: random.nextInt(4),
        status: ['todo', 'in_progress', 'done'][random.nextInt(3)],
        categoryId: random.nextInt(6) + 1,
        dueDate: DateTime.now().add(Duration(days: random.nextInt(30))),
      ),
    );
  }

  Task _mockCreateTask(Task task) {
    return task.copyWith(
      id: Random().nextInt(10000) + 100,
      createdAt: DateTime.now(),
    );
  }

  Task _mockUpdateTask(Task task) {
    return task.copyWith(updatedAt: DateTime.now());
  }

  bool _mockDeleteTask(int id) {
    return true;
  }

  void dispose() {
    _client.close();
  }

  static const List<String> _mockTitles = [
    'Finaliser le rapport mensuel',
    'Préparer la présentation client',
    'Faire les courses',
    'Aller à la salle de sport',
    'Lire le livre sur Flutter',
    'Planifier les vacances',
    'Mettre à jour le CV',
    'Réviser le code review',
    'Organiser le bureau',
    'Appeler le médecin',
  ];
}
