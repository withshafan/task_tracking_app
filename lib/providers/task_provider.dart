import 'package:flutter/material.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToTasks({required bool isAdmin, required String userEmail}) {
    _isLoading = true;
    notifyListeners();

    final stream = isAdmin
        ? _repo.getTasks()
        : _repo.getTasksForUser(userEmail);

    stream.listen((tasks) {
      _tasks = tasks;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Task> filtered({String? status, String? query}) {
    return _tasks.where((t) {
      final matchesStatus = status == null || status == 'all' || t.status.value == status;
      final matchesQuery = query == null || query.isEmpty ||
          t.title.toLowerCase().contains(query.toLowerCase());
      return matchesStatus && matchesQuery;
    }).toList();
  }
}
