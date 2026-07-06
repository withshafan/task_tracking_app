enum TaskStatus { pending, inProgress, completed }
enum TaskPriority { low, medium, high }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.pending => 'Pending',
        TaskStatus.inProgress => 'In Progress',
        TaskStatus.completed => 'Completed',
      };
  String get value => switch (this) {
        TaskStatus.pending => 'pending',
        TaskStatus.inProgress => 'in progress',
        TaskStatus.completed => 'completed',
      };
  static TaskStatus fromString(String s) => TaskStatus.values.firstWhere(
        (e) => e.value == s,
        orElse: () => TaskStatus.pending,
      );
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.priority = TaskPriority.medium,
    required this.assignedTo,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TaskStatusX.fromString(data['status'] ?? 'pending'),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == (data['priority'] ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      assignedTo: data['assignedTo'] ?? '',
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as dynamic).toDate() : null,
      dueDate: data['dueDate'] != null ? (data['dueDate'] as dynamic).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status.value,
      'priority': priority.name,
      'assignedTo': assignedTo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'dueDate': dueDate,
    };
  }
}
