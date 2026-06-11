import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/category_controller.dart';
import '../../widgets/task_card.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryChips(),
        _buildStatusFilter(),
        Expanded(
          child: Consumer<TaskController>(
            builder: (context, controller, _) {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.tasks.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadTasks(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: controller.tasks.length,
                  itemBuilder: (context, index) {
                    final task = controller.tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.taskDetail,
                          arguments: task.id,
                        );
                      },
                      onToggle: () => controller.toggleTaskStatus(task),
                      onDelete: () => _confirmDelete(task.id!),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une tâche...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TaskController>().setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<TaskController>().setSearchQuery(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<CategoryController>(
      builder: (context, catController, _) {
        if (catController.categories.isEmpty) return const SizedBox.shrink();
        final taskController = context.read<TaskController>();
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('Toutes', null, taskController),
              ...catController.categories.map((cat) {
                final isSelected = taskController.categoryFilter == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) {
                      taskController.setCategoryFilter(
                          isSelected ? null : cat.id);
                    },
                    selectedColor: AppTheme.categoryColors[cat.colorIndex % AppTheme.categoryColors.length]
                        .withValues(alpha: 0.3),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int? categoryId, TaskController controller) {
    final isSelected = controller.categoryFilter == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => controller.setCategoryFilter(isSelected ? null : categoryId),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Consumer<TaskController>(
      builder: (context, controller, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildStatusChip('Toutes', 'all', controller),
              const SizedBox(width: 8),
              _buildStatusChip('À faire', 'todo', controller),
              const SizedBox(width: 8),
              _buildStatusChip('En cours', 'in_progress', controller),
              const SizedBox(width: 8),
              _buildStatusChip('Terminées', 'done', controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, String status, TaskController controller) {
    final isSelected = controller.statusFilter == status;
    return GestureDetector(
      onTap: () => controller.setStatusFilter(isSelected ? 'all' : status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune tâche trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une nouvelle tâche pour commencer',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<TaskController>().deleteTask(taskId);
    }
  }
}

