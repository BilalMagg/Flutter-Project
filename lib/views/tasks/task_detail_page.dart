import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/category_controller.dart';
import '../../widgets/priority_badge.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskController, CategoryController>(
      builder: (context, taskController, catController, _) {
        final task = taskController.allTasks
            .where((t) => t.id == widget.taskId)
            .firstOrNull;
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détail')),
            body: const Center(child: Text('Tâche introuvable')),
          );
        }

        final category = catController.getCategoryById(task.categoryId);
        final statusLabels = {
          'todo': 'À faire',
          'in_progress': 'En cours',
          'done': 'Terminée',
        };
        final statusColors = {
          'todo': AppTheme.warningColor,
          'in_progress': AppTheme.infoColor,
          'done': AppTheme.secondaryColor,
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détail de la tâche'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.taskForm,
                    arguments: task,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PriorityBadge(priority: task.priority),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.info_outline,
                          'Statut',
                          statusLabels[task.status] ?? task.status,
                          statusColors[task.status] ?? Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.category_outlined,
                          'Catégorie',
                          category?.name ?? 'Non définie',
                          category != null
                              ? AppTheme.categoryColors[
                                  category.colorIndex % AppTheme.categoryColors.length]
                              : Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        if (task.dueDate != null)
                          _buildInfoRow(
                            Icons.date_range,
                            'Échéance',
                            DateFormat('dd MMMM yyyy', 'fr_FR')
                                .format(task.dueDate!),
                            AppTheme.errorColor,
                          ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.access_time,
                          'Créée le',
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(task.createdAt),
                          Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.update,
                          'Modifiée le',
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(task.updatedAt),
                          Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        taskController.toggleTaskStatus(task),
                    icon: Icon(task.status == 'done'
                        ? Icons.undo
                        : Icons.check_circle_outline),
                    label: Text(
                        task.status == 'done' ? 'Réouvrir' : 'Marquer terminée'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.status == 'done'
                          ? AppTheme.warningColor
                          : AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
