import 'package:flutter/material.dart';
import '../models/task.dart';
import '../app_theme.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const PriorityBadge({super.key, required this.priority});

  Color get _color => switch (priority) {
        TaskPriority.high => AppColors.danger,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.pending,
      };

  String get _label => switch (priority) {
        TaskPriority.high => 'High',
        TaskPriority.medium => 'Medium',
        TaskPriority.low => 'Low',
      };

  IconData get _icon => switch (priority) {
        TaskPriority.high => Icons.local_fire_department_rounded,
        TaskPriority.medium => Icons.circle,
        TaskPriority.low => Icons.arrow_downward_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 3),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
