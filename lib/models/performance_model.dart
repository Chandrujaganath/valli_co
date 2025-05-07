// lib/models/performance_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceModel {
  final String performanceId;
  final String userId;
  final String staffName;
  final int tasksCompleted;
  final int tasksPending;
  final double averageCompletionTime;
  final double rating;
  final String reportingPeriod;
  final Timestamp createdAt;

  PerformanceModel({
    required this.performanceId,
    required this.userId,
    required this.staffName,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.averageCompletionTime,
    required this.rating,
    required this.reportingPeriod,
    required this.createdAt,
  });

  // Factory method to create PerformanceModel from Firestore document
  factory PerformanceModel.fromDocument(DocumentSnapshot doc) {
    return PerformanceModel(
      performanceId: doc['performanceId'] ?? '',
      userId: doc['userId'] ?? '',
      staffName: doc['staffName'] ?? '',
      tasksCompleted: doc['tasksCompleted'] ?? 0,
      tasksPending: doc['tasksPending'] ?? 0,
      averageCompletionTime: (doc['averageCompletionTime'] ?? 0).toDouble(),
      rating: (doc['rating'] ?? 0).toDouble(),
      reportingPeriod: doc['reportingPeriod'] ?? 'Monthly',
      createdAt: doc['createdAt'] ?? Timestamp.now(),
    );
  }

  // Method to convert PerformanceModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'performanceId': performanceId,
      'userId': userId,
      'staffName': staffName,
      'tasksCompleted': tasksCompleted,
      'tasksPending': tasksPending,
      'averageCompletionTime': averageCompletionTime,
      'rating': rating,
      'reportingPeriod': reportingPeriod,
      'createdAt': createdAt,
    };
  }
}
