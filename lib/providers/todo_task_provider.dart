// lib/providers/todo_task_provider.dart

import 'package:flutter/material.dart';
import '../models/todo_task_model.dart';
import '../services/todo_task_service.dart';

class TodoTaskProvider with ChangeNotifier {
  final TodoTaskService _todoTaskService = TodoTaskService();

  // For Admin: Stream of all tasks
  Stream<List<TodoTaskModel>> get allTasks => _todoTaskService.getAllTasks();

  // For User: Stream of tasks assigned to the user
  Stream<List<TodoTaskModel>> getTasksByUserId(String userId) =>
      _todoTaskService.getTasksByUserId(userId);

  // Assign a new todo task
  Future<void> assignTodoTask(TodoTaskModel task) async {
    await _todoTaskService.assignTodoTask(task);
    notifyListeners();
  }

  // Update task status and progress
  Future<void> updateTaskStatusAndProgress(
      String taskId, String status, int percentageCompleted, String progressDescription) async {
    await _todoTaskService.updateTaskStatusAndProgress(
        taskId, status, percentageCompleted, progressDescription);
    notifyListeners();
  }

  // Get a single task by ID
  Future<TodoTaskModel?> getTaskById(String taskId) async {
    return await _todoTaskService.getTaskById(taskId);
  }
}
