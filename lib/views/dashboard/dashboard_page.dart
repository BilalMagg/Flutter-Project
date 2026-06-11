import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/stat_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompletionRate(controller),
                const SizedBox(height: 16),
                _buildStatsGrid(controller),
                const SizedBox(height: 24),
                _buildStatusChart(controller),
                const SizedBox(height: 24),
                _buildPriorityChart(controller),
                if (controller.categoryCounts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildCategoryChart(controller),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionRate(DashboardController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Taux de complétion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Text(
                  '${controller.completionRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: controller.completionRate / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.doneTasks} / ${controller.totalTasks} tâches terminées',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardController controller) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        StatCard(
          title: 'Total',
          value: '${controller.totalTasks}',
          icon: Icons.task_alt,
          color: AppTheme.primaryColor,
        ),
        StatCard(
          title: 'À faire',
          value: '${controller.todoTasks}',
          icon: Icons.radio_button_unchecked,
          color: AppTheme.warningColor,
        ),
        StatCard(
          title: 'En cours',
          value: '${controller.inProgressTasks}',
          icon: Icons.play_circle_outline,
          color: AppTheme.infoColor,
        ),
        StatCard(
          title: 'Terminées',
          value: '${controller.doneTasks}',
          icon: Icons.check_circle_outline,
          color: AppTheme.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildStatusChart(DashboardController controller) {
    final data = [
      _ChartData('À faire', controller.todoTasks.toDouble(), AppTheme.warningColor),
      _ChartData('En cours', controller.inProgressTasks.toDouble(), AppTheme.infoColor),
      _ChartData('Terminées', controller.doneTasks.toDouble(), AppTheme.secondaryColor),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par statut',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: data.every((d) => d.value == 0)
                  ? const Center(child: Text('Aucune donnée'))
                  : PieChart(
                      PieChartData(
                        sections: data.map((d) {
                          return PieChartSectionData(
                            value: d.value,
                            title: d.value > 0
                                ? '${(d.value / controller.totalTasks * 100).toStringAsFixed(0)}%'
                                : '',
                            color: d.color,
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.map((d) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: d.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${d.label} (${d.value.toInt()})',
                        style: const TextStyle(fontSize: 13)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChart(DashboardController controller) {
    final priorityData = controller.priorityCounts;
    if (priorityData.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppTheme.priorityLow,
      AppTheme.priorityMedium,
      AppTheme.priorityHigh,
      AppTheme.priorityCritical,
    ];
    final labels = ['Basse', 'Moyenne', 'Haute', 'Critique'];

    final data = List.generate(4, (i) {
      final entry = priorityData.firstWhere(
        (e) => e['priority'] == i,
        orElse: () => {'priority': i, 'count': 0},
      );
      return _ChartData(labels[i], (entry['count'] as int? ?? 0).toDouble(), colors[i]);
    });

    final maxValue = data.fold<double>(0, (p, v) => v.value > p ? v.value : p);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par priorité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue > 0 ? maxValue * 1.3 : 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            labels[index],
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue > 3 ? (maxValue / 3).ceilToDouble() : 1,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: entry.value.color,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(DashboardController controller) {
    final data = controller.categoryCounts;
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tâches par catégorie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...List.generate(data.length, (index) {
              final item = data[index];
              final name = item['name'] as String? ?? '';
              final count = item['count'] as int? ?? 0;
              final colorIndex = item['colorIndex'] as int? ?? 0;
              final color = AppTheme.categoryColors[
                  colorIndex % AppTheme.categoryColors.length];
              final total = controller.totalTasks;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('$count',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
