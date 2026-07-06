import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import 'status_chip.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final int index;

  const TaskCard({super.key, required this.task, required this.onTap, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(task.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  PriorityBadge(priority: task.priority),
                  const SizedBox(width: 8),
                  StatusChip(status: task.status),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(task.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (task.dueDate != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Due ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.08, end: 0);
  }
}
