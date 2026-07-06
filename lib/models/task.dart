class Task {
  final String id;
  final String title;
  final String description;
  final String status; // e.g., 'pending', 'in progress', 'completed'
  final String assignedTo; // user ID or email
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore document
  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      assignedTo: data['assignedTo'] ?? '',
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'assignedTo': assignedTo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
