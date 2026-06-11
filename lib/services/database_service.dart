import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_manager.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('DROP TABLE IF EXISTS users');
    await _createTables(db);
    await _seedCategories(db);
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorIndex INTEGER NOT NULL DEFAULT 0,
        icon TEXT NOT NULL DEFAULT 'list'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        priority INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'todo',
        categoryId INTEGER NOT NULL,
        dueDate INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      {'name': 'Personnel', 'colorIndex': 0, 'icon': 'person'},
      {'name': 'Travail', 'colorIndex': 1, 'icon': 'work'},
      {'name': 'Urgent', 'colorIndex': 2, 'icon': 'warning'},
      {'name': 'Santé', 'colorIndex': 3, 'icon': 'favorite'},
      {'name': 'Courses', 'colorIndex': 4, 'icon': 'shopping_cart'},
      {'name': 'Loisirs', 'colorIndex': 5, 'icon': 'sports_esports'},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks({String? status, int? categoryId}) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];
    if (status != null) {
      where.add('status = ?');
      whereArgs.add(status);
    }
    if (categoryId != null) {
      where.add('categoryId = ?');
      whereArgs.add(categoryId);
    }
    final result = await db.query(
      'tasks',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final result = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Task.fromMap(result.first);
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM tasks'));
    final todo = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM tasks WHERE status = 'todo'"));
    final inProgress = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM tasks WHERE status = 'in_progress'"));
    final done = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM tasks WHERE status = 'done'"));

    final priorityCounts = await db.rawQuery(
      'SELECT priority, COUNT(*) as count FROM tasks GROUP BY priority',
    );

    final categoryCounts = await db.rawQuery(
      'SELECT c.name, c.colorIndex, COUNT(t.id) as count FROM categories c LEFT JOIN tasks t ON c.id = t.categoryId GROUP BY c.id',
    );

    return {
      'total': total ?? 0,
      'todo': todo ?? 0,
      'inProgress': inProgress ?? 0,
      'done': done ?? 0,
      'priorityCounts': priorityCounts,
      'categoryCounts': categoryCounts,
    };
  }
}
