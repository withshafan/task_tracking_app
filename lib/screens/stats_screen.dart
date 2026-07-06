import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/task.dart';
import '../models/user.dart';

class StatsScreen extends StatefulWidget {
  final AppUser currentUser;
  const StatsScreen({super.key, required this.currentUser});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    // For interns: show personal stats
    // For admins: show overall stats
    final isAdmin = widget.currentUser.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'My Progress'),
        backgroundColor: Colors.blue,
      ),
      body: isAdmin
          ? _buildAdminStats()
          : _buildInternStats(),
    );
  }

  Widget _buildInternStats() {
    return StreamBuilder<List<Task>>(
      stream: _firestore.getTasksForUser(widget.currentUser.email),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data ?? [];
        final total = tasks.length;
        final completed = tasks.where((t) => t.status == 'completed').length;
        final pending = tasks.where((t) => t.status == 'pending').length;
        final inProgress = tasks.where((t) => t.status == 'in progress').length;
        final completionRate = total > 0 ? (completed / total * 100) : 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Task Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildStatCard('Total Tasks', total, Colors.blue),
              _buildStatCard('Completed', completed, Colors.green),
              _buildStatCard('In Progress', inProgress, Colors.orange),
              _buildStatCard('Pending', pending, Colors.grey),
              const SizedBox(height: 30),
              Text(
                'Completion Rate: ${completionRate.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
                minHeight: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminStats() {
    return StreamBuilder<List<Task>>(
      stream: _firestore.getTasks(),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.hasError) {
          return Center(child: Text('Error: ${taskSnapshot.error}'));
        }
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = taskSnapshot.data ?? [];
        final total = tasks.length;
        final completed = tasks.where((t) => t.status == 'completed').length;
        final pending = tasks.where((t) => t.status == 'pending').length;
        final inProgress = tasks.where((t) => t.status == 'in progress').length;
        final completionRate = total > 0 ? (completed / total * 100) : 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Organization Stats',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildStatCard('Total Tasks', total, Colors.blue),
              _buildStatCard('Completed', completed, Colors.green),
              _buildStatCard('In Progress', inProgress, Colors.orange),
              _buildStatCard('Pending', pending, Colors.grey),
              const SizedBox(height: 30),
              Text(
                'Overall Completion: ${completionRate.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
                minHeight: 12,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const Text(
                'Intern Performance (Coming Soon)',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              // Future improvement: list each intern with their stats
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Chip(
              label: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: color.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }
}
