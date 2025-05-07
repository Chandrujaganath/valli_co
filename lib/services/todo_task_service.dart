// lib/services/todo_task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_task_model.dart';

class TodoTaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Assign a new todo task to a user
  Future<void> assignTodoTask(TodoTaskModel task) async {
    try {
      await _db.collection('todo_tasks').doc(task.taskId).set(task.toJson());
    } catch (e) {
      throw Exception('Error assigning todo task: $e');
    }
  }

  // Get todo tasks assigned to a specific user
  Stream<List<TodoTaskModel>> getTasksByUserId(String userId) {
    try {
      return _db
          .collection('todo_tasks')
          .where('assignedTo', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => TodoTaskModel.fromDocument(doc)).toList());
    } catch (e) {
      throw Exception('Error fetching todo tasks: $e');
    }
  }

  // Get all todo tasks (admin)
  Stream<List<TodoTaskModel>> getAllTasks() {
    try {
      return _db
          .collection('todo_tasks')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => TodoTaskModel.fromDocument(doc)).toList());
    } catch (e) {
      throw Exception('Error fetching all todo tasks: $e');
    }
  }

  // Update task status, percentage, progress description, and record the update in history.
  Future<void> updateTaskStatusAndProgress(
      String taskId, String status, int percentageCompleted, String progressDescription) async {
    try {
      final Timestamp now = Timestamp.now();
      Map<String, dynamic> updateEntry = {
        'status': status,
        'percentageCompleted': percentageCompleted,
        'progressDescription': progressDescription,
        'updatedAt': now,
      };
      Map<String, dynamic> data = {
        'status': status,
        'percentageCompleted': percentageCompleted,
        'progressDescription': progressDescription,
        'updatedAt': now,
        'updateHistory': FieldValue.arrayUnion([updateEntry]),
      };
      await _db.collection('todo_tasks').doc(taskId).update(data);
    } catch (e) {
      throw Exception('Error updating todo task: $e');
    }
  }

  // Get a single todo task by ID
  Future<TodoTaskModel?> getTaskById(String taskId) async {
    try {
      DocumentSnapshot doc = await _db.collection('todo_tasks').doc(taskId).get();
      if (doc.exists) {
        return TodoTaskModel.fromDocument(doc);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error fetching todo task: $e');
    }
  }

  // getTasksByUserIdStreamOnce
  Future<List<TodoTaskModel>> getTasksByUserIdStreamOnce(String userId) async {
    final snapshot = await _db
        .collection('todoTasks')
        .where('assignedTo', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => TodoTaskModel.fromDocument(doc)).toList();
  }
}
