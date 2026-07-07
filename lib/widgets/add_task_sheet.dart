import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final AppUser currentUser;
  final Function(Task) onTaskAdded;

  const AddTaskSheet({
    super.key,
    required this.currentUser,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _userService = UserService();

  TaskStatus _selectedStatus = TaskStatus.pending;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  String _selectedAssignee = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.currentUser.isAdmin) {
      _selectedAssignee = widget.currentUser.email;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return; // Prevent double taps

    setState(() => _isSubmitting = true);

    try {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        assignedTo: _selectedAssignee.isEmpty ? widget.currentUser.email : _selectedAssignee,
        createdAt: DateTime.now(),
        dueDate: _selectedDueDate,
      );
      await widget.onTaskAdded(task);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Task',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // Priority and Status in a row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: TaskPriority.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Icon(
                                p == TaskPriority.high
                                    ? Icons.local_fire_department_rounded
                                    : p == TaskPriority.medium
                                        ? Icons.circle
                                        : Icons.arrow_downward_rounded,
                                size: 16,
                                color: p == TaskPriority.high
                                    ? AppColors.danger
                                    : p == TaskPriority.medium
                                        ? AppColors.warning
                                        : AppColors.pending,
                              ),
                              Text('${p.name[0].toUpperCase()}${p.name.substring(1)}'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedPriority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: TaskStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.label));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Assign to (admin only)
              if (widget.currentUser.isAdmin) ...[
                StreamBuilder<List<AppUser>>(
                  stream: _userService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading users');
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final usersList = snapshot.data!;
                    if (usersList.isEmpty) {
                      return TextFormField(
                        initialValue: 'No users available',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Assign To',
                          prefixIcon: Icon(Icons.person_add_outlined),
                        ),
                      );
                    }
                    
                    // Make sure selected assignee is in the list, else null
                    final bool isValid = usersList.any((u) => u.email == _selectedAssignee);
                    final currentValue = isValid ? _selectedAssignee : null;

                    return DropdownButtonFormField<String>(
                      initialValue: currentValue,
                      hint: const Text('Select Assignee'),
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        prefixIcon: Icon(Icons.person_add_outlined),
                      ),
                      items: usersList.map((user) {
                        return DropdownMenuItem(
                          value: user.email,
                          child: Text('${user.name} (${user.email})'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedAssignee = v!),
                      validator: (v) => v == null || v.isEmpty ? 'Please select an assignee' : null,
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Due date
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDueDate = picked);
                  }
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
                        color: _selectedDueDate != null
                            ? AppColors.primary
                            : AppColors.pending,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDueDate == null
                            ? 'Set Due Date (optional)'
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

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Create Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
