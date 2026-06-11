import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/tasks/task_list_page.dart';
import 'views/tasks/task_detail_page.dart';
import 'views/tasks/task_form_page.dart';
import 'views/categories/category_page.dart';
import 'views/dashboard/dashboard_page.dart';
import 'views/profile/profile_page.dart';
import 'models/task.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'TaskFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: auth.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: const Locale('fr', 'FR'),
            initialRoute: AppRoutes.login,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRoutes.login:
                  return MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  );
                case AppRoutes.register:
                  return MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  );
                case AppRoutes.home:
                  return MaterialPageRoute(
                    builder: (_) => const HomePage(),
                  );
                case AppRoutes.taskDetail:
                  final taskId = settings.arguments as int;
                  return MaterialPageRoute(
                    builder: (_) => TaskDetailPage(taskId: taskId),
                  );
                case AppRoutes.taskForm:
                  final task = settings.arguments as Task?;
                  return MaterialPageRoute(
                    builder: (_) => TaskFormPage(task: task),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TaskListPage(),
    DashboardPage(),
    CategoryPage(),
    ProfilePage(),
  ];

  final List<String> _titles = [
    'Mes Tâches',
    'Tableau de bord',
    'Catégories',
    'Profil',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptions,
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final taskCtrl = context.read<TaskController>();
                final dashCtrl = context.read<DashboardController>();
                await Navigator.pushNamed(context, AppRoutes.taskForm);
                if (mounted) {
                  taskCtrl.loadTasks();
                  dashCtrl.loadStats();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catégories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    final controller = context.read<TaskController>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trier par',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Date de création'),
              onTap: () {
                controller.setSortBy('createdAt');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Priorité'),
              onTap: () {
                controller.setSortBy('priority');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date d\'échéance'),
              onTap: () {
                controller.setSortBy('dueDate');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Titre'),
              onTap: () {
                controller.setSortBy('title');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
