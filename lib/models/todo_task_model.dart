// lib/models/todo_task_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TodoTaskModel {
  final String taskId;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedBy;
  final String status;
  final int percentageCompleted;
  final String progressDescription;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? dueDate;
  final List<dynamic>? updateHistory; // Update history entries

  TodoTaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.percentageCompleted,
    required this.progressDescription,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.updateHistory,
  });

  factory TodoTaskModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoTaskModel(
      taskId: data['taskId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      status: data['status'] ?? '',
      percentageCompleted: data['percentageCompleted'] ?? 0,
      progressDescription: data['progressDescription'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      dueDate: data['dueDate'],
      updateHistory: data['updateHistory'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'status': status,
      'percentageCompleted': percentageCompleted,
      'progressDescription': progressDescription,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'dueDate': dueDate,
      'updateHistory': updateHistory ?? [],
    };
  }
}
