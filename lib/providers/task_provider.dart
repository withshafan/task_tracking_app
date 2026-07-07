import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<Task>>? _subscription;

  // Sort options
  String _sortBy = 'createdAt'; // 'createdAt', 'dueDate', 'priority'

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get sortBy => _sortBy;

  void setSortBy(String value) {
    _sortBy = value;
    _applySorting();
    notifyListeners();
  }

  void listenToTasks({required bool isAdmin, required String userEmail}) {
    // Cancel any existing subscription to prevent memory leaks
    _subscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    final stream = isAdmin ? _repo.getTasks() : _repo.getTasksForUser(userEmail);

    _subscription = stream.listen(
      (tasks) {
        _tasks = tasks;
        _applySorting();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'dueDate':
        _tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'priority':
        const order = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
        _tasks.sort((a, b) => (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1));
        break;
      default:
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  List<Task> filtered({String? status, String? query}) {
    return _tasks.where((t) {
      final matchesStatus = status == null || status == 'all' || t.status.value == status;
      final matchesQuery =
          query == null || query.isEmpty || t.title.toLowerCase().contains(query.toLowerCase());
      return matchesStatus && matchesQuery;
    }).toList();
  }

  // Task counts for summary cards
  int get totalCount => _tasks.length;
  int get pendingCount => _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get inProgressCount => _tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get completedCount => _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get overdueCount => _tasks
      .where((t) =>
          t.dueDate != null &&
          t.dueDate!.isBefore(DateTime.now()) &&
          t.status != TaskStatus.completed)
      .length;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
