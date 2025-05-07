// lib/services/task_service.dart

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../utils/constants.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all tasks
  Future<List<TaskModel>> getAllTasks() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.tasks)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching tasks: $e');
      throw Exception('Failed to fetch tasks');
    }
  }

  // Fetch only pending tasks (for TAT monitoring)
  Future<List<TaskModel>> getPendingTasks() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.tasks)
          .where('status', isEqualTo: Statuses.pending)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching pending tasks: $e');
      throw Exception('Failed to fetch pending tasks');
    }
  }

  // Add a new task
  Future<void> addTask(TaskModel task) async {
    try {
      await _firestore.collection(FirestoreCollections.tasks).add(task.toJson());
    } catch (e) {
      print('Error adding task: $e');
      throw Exception('Failed to add task');
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _firestore
          .collection(FirestoreCollections.tasks)
          .doc(taskId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating task status: $e');
      throw Exception('Failed to update task status');
    }
  }

  // Mark task as completed with actual completion date
  Future<void> completeTask(String taskId, Timestamp completionDate) async {
    try {
      await _firestore
          .collection(FirestoreCollections.tasks)
          .doc(taskId)
          .update({
            'status': Statuses.completed,
            'actualCompletionDate': completionDate,
          });
    } catch (e) {
      print('Error completing task: $e');
      throw Exception('Failed to complete task');
    }
  }
}
