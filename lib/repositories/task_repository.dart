import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  // Create a new task
  Future<void> addTask(Task task) async {
    await _tasksCollection.doc(task.id).set(task.toMap());
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // Get all tasks (real‑time stream)
  Stream<List<Task>> getTasks() {
    return _tasksCollection.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  // Get tasks assigned to a specific user (optional)
  Stream<List<Task>> getTasksForUser(String userId) {
    return _tasksCollection
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Task.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }
}
