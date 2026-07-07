import 'package:flutter/material.dart';
import '../models/task.dart';
import '../app_theme.dart';

class StatusChip extends StatelessWidget {
  final TaskStatus status;
  const StatusChip({super.key, required this.status});

  Color get _color => switch (status) {
        TaskStatus.completed => AppColors.success,
        TaskStatus.inProgress => AppColors.warning,
        TaskStatus.pending => AppColors.pending,
      };

  IconData get _icon => switch (status) {
        TaskStatus.completed => Icons.check_circle_rounded,
        TaskStatus.inProgress => Icons.bolt_rounded,
        TaskStatus.pending => Icons.schedule_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: _color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
