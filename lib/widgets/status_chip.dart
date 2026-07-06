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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
