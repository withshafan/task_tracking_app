import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
      ),
      body: isAdmin ? _buildAdminStats() : _buildInternStats(),
    );
  }

  Widget _buildInternStats() {
    return StreamBuilder<List<Task>>(
      stream: _repo.getTasksForUser(widget.currentUser.email),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks to report stats.'));
        }
        final total = tasks.length;
        final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final completionRate = total > 0 ? (completed / total * 100) : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Task Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (completed > 0)
                        PieChartSectionData(
                          value: completed.toDouble(),
                          color: AppColors.success,
                          title: '$completed',
                          radius: 50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      if (inProgress > 0)
                        PieChartSectionData(
                          value: inProgress.toDouble(),
                          color: AppColors.warning,
                          title: '$inProgress',
                          radius: 50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      if (pending > 0)
                        PieChartSectionData(
                          value: pending.toDouble(),
                          color: AppColors.pending,
                          title: '$pending',
                          radius: 50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ],
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildStatCard('Total Tasks', total, AppColors.primary),
              _buildStatCard('Completed', completed, AppColors.success),
              _buildStatCard('In Progress', inProgress, AppColors.warning),
              _buildStatCard('Pending', pending, AppColors.pending),
              const SizedBox(height: 30),
              Text(
                'Completion Rate: ${completionRate.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionRate / 100,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.primary,
                  minHeight: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminStats() {
    return StreamBuilder<List<Task>>(
      stream: _repo.getTasks(),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.hasError) {
          return Center(child: Text('Error: ${taskSnapshot.error}'));
        }
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = taskSnapshot.data ?? [];
        final total = tasks.length;
        final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
        final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        final completionRate = total > 0 ? (completed / total * 100) : 0;

        return StreamBuilder<List<AppUser>>(
          stream: _userService.getAllUsers(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Center(child: Text('Error loading users'));
            }
            final users = userSnapshot.data ?? [];
            final interns = users.where((u) => !u.isAdmin).toList();

            // Calculate leaderboards
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Organization Stats',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (total > 0)
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            if (completed > 0)
                              PieChartSectionData(
                                value: completed.toDouble(),
                                color: AppColors.success,
                                title: '$completed',
                                radius: 45,
                                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (inProgress > 0)
                              PieChartSectionData(
                                value: inProgress.toDouble(),
                                color: AppColors.warning,
                                title: '$inProgress',
                                radius: 45,
                                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            if (pending > 0)
                              PieChartSectionData(
                                value: pending.toDouble(),
                                color: AppColors.pending,
                                title: '$pending',
                                radius: 45,
                                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                          ],
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildStatCard('Total Tasks', total, AppColors.primary),
                  _buildStatCard('Completed', completed, AppColors.success),
                  _buildStatCard('In Progress', inProgress, AppColors.warning),
                  _buildStatCard('Pending', pending, AppColors.pending),
                  const SizedBox(height: 20),
                  Text(
                    'Overall Completion: ${completionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: completionRate / 100,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primary,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Intern Leaderboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (leaderboard.isEmpty)
                    const Text('No interns found.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leaderboard.length,
                      itemBuilder: (context, index) {
                        final item = leaderboard[index];
                        final AppUser user = item['user'];
                        final double rate = item['rate'];
                        final int tot = item['total'];
                        final int comp = item['completed'];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index == 0
                                  ? Colors.amber
                                  : index == 1
                                      ? Colors.grey[300]
                                      : index == 2
                                          ? Colors.brown[300]
                                          : Colors.grey[400],
                              child: Text(
                                '#${index + 1}',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${user.email} • $comp/$tot tasks completed'),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: rate,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[200],
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${(rate * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
