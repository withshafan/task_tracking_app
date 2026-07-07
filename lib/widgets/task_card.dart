import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../app_theme.dart';
import 'status_chip.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onComplete,
    this.onDelete,
    this.index = 0,
  });

  Color get _priorityAccent => switch (task.priority) {
        TaskPriority.high => AppColors.danger,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.pending,
      };

  bool get _isOverdue =>
      task.dueDate != null &&
      task.dueDate!.isBefore(DateTime.now()) &&
      task.status != TaskStatus.completed;

  bool get _isDueToday {
    if (task.dueDate == null) return false;
    final now = DateTime.now();
    return task.dueDate!.year == now.year &&
        task.dueDate!.month == now.month &&
        task.dueDate!.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: _priorityAccent, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    // Quick complete checkbox
                    if (task.status != TaskStatus.completed && onComplete != null)
                      GestureDetector(
                        onTap: onComplete,
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.pending.withAlpha(100),
                              width: 2,
                            ),
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      )
                    else if (task.status == TaskStatus.completed)
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status == TaskStatus.completed
                              ? Theme.of(context).textTheme.bodySmall?.color?.withAlpha(120)
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: task.status),
                  ],
                ),

                // Description
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      task.description,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(140),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Bottom row: due date + priority
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Row(
                    children: [
                      if (task.dueDate != null) ...[
                        Icon(
                          _isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.calendar_today_outlined,
                          size: 13,
                          color: _isOverdue
                              ? AppColors.danger
                              : _isDueToday
                                  ? AppColors.warning
                                  : AppColors.pending,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isOverdue
                              ? 'Overdue · ${DateFormat.MMMd().format(task.dueDate!)}'
                              : _isDueToday
                                  ? 'Due Today'
                                  : 'Due ${DateFormat.MMMd().format(task.dueDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _isOverdue ? FontWeight.w600 : FontWeight.w400,
                            color: _isOverdue
                                ? AppColors.danger
                                : _isDueToday
                                    ? AppColors.warning
                                    : AppColors.pending,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      PriorityBadge(priority: task.priority),
                      const Spacer(),
                      // Assigned to
                      Text(
                        task.assignedTo.split('@').first,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap in dismissible for swipe actions
    if (onDelete != null || onComplete != null) {
      card = Dismissible(
        key: ValueKey(task.id),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.delete_outline_rounded, color: Colors.white),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onComplete?.call();
            return false; // Don't actually dismiss, just trigger the callback
          } else {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ??
                false;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onDelete?.call();
          }
        },
        child: card,
      );
    }

    return card.animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}
