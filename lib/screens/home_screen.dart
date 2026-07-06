import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  final UserService _userService = UserService();

  // Controllers & variables for Add Task dialog
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedStatus = 'pending';
  String _selectedAssignee = ''; // email of assigned user

  // Current user data
  AppUser? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final appUser = await _userService.getUser(user.uid);
      setState(() {
        _currentUser = appUser;
        _isLoadingUser = false;
      });
    }
  }

  // Show dialog to add a new task
  void _showAddTaskDialog() {
    // If admin, we need a list of interns to assign to
    // If intern, assign to self
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add New Task'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  // Status
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'in progress', child: Text('In Progress')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Assign to – only shown for admin
                  if (_currentUser!.isAdmin) ...[
                    StreamBuilder<List<AppUser>>(
                      stream: _userService.getAllUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Error loading users');
                        }
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        // Filter out admins (only interns)
                        final interns =
                            snapshot.data!.where((u) => !u.isAdmin).toList();
                        // Set default if not set
                        if (_selectedAssignee.isEmpty && interns.isNotEmpty) {
                          _selectedAssignee = interns.first.email;
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedAssignee.isEmpty && interns.isNotEmpty
                              ? interns.first.email
                              : _selectedAssignee,
                          decoration:
                              const InputDecoration(labelText: 'Assign To'),
                          items: interns.map((user) {
                            return DropdownMenuItem(
                              value: user.email,
                              child: Text('${user.name} (${user.email})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateDialog(() {
                              _selectedAssignee = value!;
                            });
                          },
                        );
                      },
                    ),
                  ] else ...[
                    // Intern: assign to self (read‑only)
                    Text(
                      'Assign to: ${_currentUser!.email}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _titleController.clear();
                  _descController.clear();
                  _selectedStatus = 'pending';
                  _selectedAssignee = '';
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;

                  String assigneeEmail;
                  if (_currentUser!.isAdmin) {
                    assigneeEmail = _selectedAssignee;
                  } else {
                    assigneeEmail = _currentUser!.email;
                  }

                  final newTask = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    status: _selectedStatus,
                    assignedTo: assigneeEmail,
                    createdAt: DateTime.now(),
                  );
                  await _firestore.addTask(newTask);
                  _titleController.clear();
                  _descController.clear();
                  _selectedStatus = 'pending';
                  _selectedAssignee = '';
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Sign out
  void _signOut() async {
    await _auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine the stream to use based on role
    Stream<List<Task>> taskStream;
    if (_currentUser!.isAdmin) {
      // Admin sees all tasks
      taskStream = _firestore.getTasks();
    } else {
      // Intern sees only their own tasks
      taskStream = _firestore.getTasksForUser(_currentUser!.email);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser!.isAdmin
              ? 'All Tasks (Admin)'
              : 'My Tasks (${_currentUser!.name})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: taskStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks yet. Add one!'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Chip(
                    label: Text(task.status),
                    backgroundColor: task.status == 'completed'
                        ? Colors.green
                        : task.status == 'in progress'
                            ? Colors.orange
                            : Colors.grey,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                    // The stream will auto‑refresh.
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
