import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/user_service.dart';

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
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
      widget.onTaskAdded(task);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add New Task',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: TaskStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name[0].toUpperCase() + priority.name.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
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
                    final interns = snapshot.data!.where((u) => !u.isAdmin).toList();
                    if (_selectedAssignee.isEmpty && interns.isNotEmpty) {
                      _selectedAssignee = interns.first.email;
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedAssignee.isEmpty && interns.isNotEmpty
                          ? interns.first.email
                          : _selectedAssignee,
                      decoration: const InputDecoration(labelText: 'Assign To'),
                      items: interns.map((user) {
                        return DropdownMenuItem(
                          value: user.email,
                          child: Text('${user.name} (${user.email})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAssignee = value!;
                        });
                      },
                    );
                  },
                ),
              ] else ...[
                Text(
                  'Assign to: ${widget.currentUser.email}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDueDate == null
                          ? 'No Due Date Selected'
                          : 'Due Date: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDueDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Task'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
