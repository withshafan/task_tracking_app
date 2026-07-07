import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../repositories/task_repository.dart';
import '../services/user_service.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../app_theme.dart';

class StatsScreen extends StatefulWidget {
  final AppUser currentUser;
  const StatsScreen({super.key, required this.currentUser});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final TaskRepository _repo = TaskRepository();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'My Progress'),
        automaticallyImplyLeading: false,
      ),
      body: isAdmin ? _buildAdminStats() : _buildInternStats(),
    );
  }

  // ─── Stat Card ────────────────────────────────────────────────────────────
  Widget _buildGradientStatCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withAlpha(180)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withAlpha(200), size: 22),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          .animate(delay: (index * 100).ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1, end: 0),
    );
  }

  // ─── Intern Stats ──────────────────────────────────────────────────────────
  Widget _buildInternStats() {
    return StreamBuilder<List<Task>>(
      stream: _repo.getTasksForUser(widget.currentUser.email),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded, size: 64, color: AppColors.pending.withAlpha(100)),
                const SizedBox(height: 12),
                const Text('No tasks to show stats'),
              ],
            ),
          );
        }
        final total = tasks.length;
        final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final completionRate = total > 0 ? (completed / total * 100) : 0.0;

        // Weekly data
        final weeklyData = _getWeeklyCompletions(tasks);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat cards
              Row(
                children: [
                  _buildGradientStatCard(
                    label: 'Total',
                    count: total,
                    icon: Icons.assignment_rounded,
                    color: AppColors.primary,
                    index: 0,
                  ),
                  const SizedBox(width: 10),
                  _buildGradientStatCard(
                    label: 'Done',
                    count: completed,
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    index: 1,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildGradientStatCard(
                    label: 'Active',
                    count: inProgress,
                    icon: Icons.bolt_rounded,
                    color: AppColors.warning,
                    index: 2,
                  ),
                  const SizedBox(width: 10),
                  _buildGradientStatCard(
                    label: 'Pending',
                    count: pending,
                    icon: Icons.schedule_rounded,
                    color: AppColors.pending,
                    index: 3,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Completion rate
              _buildCompletionProgress(completionRate),

              const SizedBox(height: 28),

              // Donut chart
              _buildSection('Task Breakdown'),
              const SizedBox(height: 12),
              _buildDonutChart(completed, inProgress, pending),

              const SizedBox(height: 28),

              // Weekly chart
              _buildSection('This Week\'s Activity'),
              const SizedBox(height: 12),
              _buildWeeklyChart(weeklyData),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // ─── Admin Stats ──────────────────────────────────────────────────────────
  Widget _buildAdminStats() {
    return StreamBuilder<List<Task>>(
      stream: _repo.getTasks(),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.hasError) return Center(child: Text('Error: ${taskSnapshot.error}'));
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = taskSnapshot.data ?? [];
        final total = tasks.length;
        final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final completionRate = total > 0 ? (completed / total * 100) : 0.0;
        final weeklyData = _getWeeklyCompletions(tasks);

        return StreamBuilder<List<AppUser>>(
          stream: _userService.getAllUsers(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) return const Center(child: Text('Error loading users'));
            final users = userSnapshot.data ?? [];
            final interns = users.where((u) => !u.isAdmin).toList();

            // Leaderboard
            final List<Map<String, dynamic>> leaderboard = [];
            for (var intern in interns) {
              final internTasks = tasks.where((t) => t.assignedTo == intern.email).toList();
              final totalInt = internTasks.length;
              final compInt = internTasks.where((t) => t.status == TaskStatus.completed).length;
              final rate = totalInt > 0 ? (compInt / totalInt) : 0.0;
              leaderboard.add({
                'user': intern,
                'total': totalInt,
                'completed': compInt,
                'rate': rate,
              });
            }
            leaderboard.sort((a, b) => b['rate'].compareTo(a['rate']));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat cards
                  Row(
                    children: [
                      _buildGradientStatCard(
                        label: 'Total', count: total,
                        icon: Icons.assignment_rounded, color: AppColors.primary, index: 0,
                      ),
                      const SizedBox(width: 10),
                      _buildGradientStatCard(
                        label: 'Done', count: completed,
                        icon: Icons.check_circle_rounded, color: AppColors.success, index: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildGradientStatCard(
                        label: 'Active', count: inProgress,
                        icon: Icons.bolt_rounded, color: AppColors.warning, index: 2,
                      ),
                      const SizedBox(width: 10),
                      _buildGradientStatCard(
                        label: 'Pending', count: pending,
                        icon: Icons.schedule_rounded, color: AppColors.pending, index: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _buildCompletionProgress(completionRate),
                  const SizedBox(height: 28),

                  if (total > 0) ...[
                    _buildSection('Task Breakdown'),
                    const SizedBox(height: 12),
                    _buildDonutChart(completed, inProgress, pending),
                    const SizedBox(height: 28),
                  ],

                  _buildSection('Weekly Activity'),
                  const SizedBox(height: 12),
                  _buildWeeklyChart(weeklyData),

                  const SizedBox(height: 28),

                  // Leaderboard
                  _buildSection('Team Leaderboard'),
                  const SizedBox(height: 12),
                  if (leaderboard.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Text('No team members yet')),
                    )
                  else
                    ...leaderboard.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final AppUser user = item['user'];
                      final double rate = item['rate'];
                      final int tot = item['total'];
                      final int comp = item['completed'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: index == 0
                              ? Border.all(color: Colors.amber.withAlpha(80), width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Rank
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == 0
                                    ? Colors.amber
                                    : index == 1
                                        ? const Color(0xFFC0C0C0)
                                        : index == 2
                                            ? const Color(0xFFCD7F32)
                                            : AppColors.pending.withAlpha(40),
                              ),
                              child: Center(
                                child: index < 3
                                    ? Text(
                                        ['🥇', '🥈', '🥉'][index],
                                        style: const TextStyle(fontSize: 16),
                                      )
                                    : Text(
                                        '#${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$comp / $tot tasks completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(150),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: rate,
                                      minHeight: 5,
                                      backgroundColor: AppColors.pending.withAlpha(30),
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(rate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: rate >= 0.7
                                    ? AppColors.success
                                    : rate >= 0.4
                                        ? AppColors.warning
                                        : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(delay: (index * 80).ms)
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: 0.05, end: 0);
                    }),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Shared Widgets ────────────────────────────────────────────────────────
  Widget _buildSection(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildCompletionProgress(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Completion Rate',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: rate >= 70
                      ? AppColors.success
                      : rate >= 40
                          ? AppColors.warning
                          : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: AppColors.pending.withAlpha(30),
              color: rate >= 70
                  ? AppColors.success
                  : rate >= 40
                      ? AppColors.warning
                      : AppColors.danger,
              minHeight: 10,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildDonutChart(int completed, int inProgress, int pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: [
                  if (completed > 0)
                    PieChartSectionData(
                      value: completed.toDouble(),
                      color: AppColors.success,
                      title: '$completed',
                      radius: 28,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  if (inProgress > 0)
                    PieChartSectionData(
                      value: inProgress.toDouble(),
                      color: AppColors.warning,
                      title: '$inProgress',
                      radius: 28,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  if (pending > 0)
                    PieChartSectionData(
                      value: pending.toDouble(),
                      color: AppColors.pending,
                      title: '$pending',
                      radius: 28,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 36,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem('Completed', completed, AppColors.success),
                const SizedBox(height: 10),
                _legendItem('In Progress', inProgress, AppColors.warning),
                const SizedBox(height: 10),
                _legendItem('Pending', pending, AppColors.pending),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(
          '$count',
          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<double> data) {
    final dayLabels = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat.E().format(day);
    });

    final maxVal = data.fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal < 1 ? 5 : maxVal + 2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dayLabels[value.toInt()],
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value == value.roundToDouble()) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(fontSize: 10, color: AppColors.pending),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  List<double> _getWeeklyCompletions(List<Task> tasks) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final nextDay = day.add(const Duration(days: 1));
      return tasks
          .where((t) =>
              t.status == TaskStatus.completed &&
              t.updatedAt != null &&
              t.updatedAt!.isAfter(day) &&
              t.updatedAt!.isBefore(nextDay))
          .length
          .toDouble();
    });
  }
}
