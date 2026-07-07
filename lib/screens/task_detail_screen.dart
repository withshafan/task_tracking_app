import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskRepository _repo = TaskRepository();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TaskStatus _selectedStatus;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDueDate;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _selectedStatus = widget.task.status;
    _selectedPriority = widget.task.priority;
    _selectedDueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color get _priorityColor => switch (_selectedPriority) {
        TaskPriority.high => AppColors.danger,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.pending,
      };

  void _updateTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedTask = Task(
        id: widget.task.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        assignedTo: widget.task.assignedTo,
        createdAt: widget.task.createdAt,
        updatedAt: DateTime.now(),
        dueDate: _selectedDueDate,
      );
      await _repo.updateTask(updatedTask);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Task updated successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.danger),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Delete Task?'),
          ],
        ),
        content: const Text('This action cannot be undone. The task will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _repo.deleteTask(widget.task.id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.danger),
          );
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: _priorityColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_priorityColor, _priorityColor.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_selectedPriority.name[0].toUpperCase()}${_selectedPriority.name.substring(1)} Priority',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedStatus.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_isDeleting)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _deleteTask,
                  tooltip: 'Delete',
                ),
            ],
          ),

          // Status timeline
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildStatusStep(
                      'Pending',
                      Icons.schedule_rounded,
                      _selectedStatus == TaskStatus.pending ||
                          _selectedStatus == TaskStatus.inProgress ||
                          _selectedStatus == TaskStatus.completed,
                      _selectedStatus == TaskStatus.pending,
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _selectedStatus == TaskStatus.inProgress ||
                                _selectedStatus == TaskStatus.completed
                            ? AppColors.success
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    _buildStatusStep(
                      'In Progress',
                      Icons.bolt_rounded,
                      _selectedStatus == TaskStatus.inProgress ||
                          _selectedStatus == TaskStatus.completed,
                      _selectedStatus == TaskStatus.inProgress,
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _selectedStatus == TaskStatus.completed
                            ? AppColors.success
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    _buildStatusStep(
                      'Done',
                      Icons.check_circle_rounded,
                      _selectedStatus == TaskStatus.completed,
                      _selectedStatus == TaskStatus.completed,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form fields
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text('Title', style: _sectionLabel(context)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text('Description', style: _sectionLabel(context)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),

                  const SizedBox(height: 20),

                  // Status & Priority
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', style: _sectionLabel(context)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<TaskStatus>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: TaskStatus.values.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s.label));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedStatus = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Priority', style: _sectionLabel(context)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<TaskPriority>(
                              initialValue: _selectedPriority,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: TaskPriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.name[0].toUpperCase()}${p.name.substring(1)}'),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedPriority = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Due date
                  Text('Due Date', style: _sectionLabel(context)),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _selectedDueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
                            color: _selectedDueDate != null ? AppColors.primary : AppColors.pending,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueDate == null
                                ? 'No due date set'
                                : DateFormat.yMMMd().format(_selectedDueDate!),
                            style: TextStyle(
                              color: _selectedDueDate != null ? null : AppColors.pending,
                              fontWeight:
                                  _selectedDueDate != null ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDueDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedDueDate = null),
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.pending),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Metadata
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _metadataRow(
                          Icons.person_outline_rounded,
                          'Assigned to',
                          widget.task.assignedTo,
                        ),
                        const Divider(height: 20),
                        _metadataRow(
                          Icons.access_time_rounded,
                          'Created',
                          DateFormat.yMMMd().add_jm().format(widget.task.createdAt.toLocal()),
                        ),
                        if (widget.task.updatedAt != null) ...[
                          const Divider(height: 20),
                          _metadataRow(
                            Icons.update_rounded,
                            'Last updated',
                            DateFormat.yMMMd().add_jm().format(widget.task.updatedAt!.toLocal()),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateTask,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Save Changes',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String label, IconData icon, bool reached, bool active) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? AppColors.success : Theme.of(context).dividerColor,
            border: active
                ? Border.all(color: AppColors.success, width: 3)
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: reached ? Colors.white : AppColors.pending,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: reached ? AppColors.success : AppColors.pending,
          ),
        ),
      ],
    );
  }

  Widget _metadataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.pending),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.pending,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  TextStyle? _sectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );
  }
}
