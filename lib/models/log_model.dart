// lib/models/log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LogModel {
  final String logId;
  final String userId;
  final String name;
  final String action; // e.g., 'Login', 'Logout', 'Data Update'
  final Timestamp timestamp;
  final String details; // Additional details of the action

  LogModel({
    required this.logId,
    required this.userId,
    required this.name,
    required this.action,
    required this.timestamp,
    required this.details,
  });

  // Convert Firestore document to LogModel
  factory LogModel.fromDocument(DocumentSnapshot doc) {
    return LogModel(
      logId: doc['logId'] ?? '',
      userId: doc['userId'] ?? '',
      name: doc['name'] ?? '',
      action: doc['action'] ?? '',
      timestamp: doc['timestamp'] ?? Timestamp.now(),
      details: doc['details'] ?? '',
    );
  }

  // Convert LogModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'userId': userId,
      'name': name,
      'action': action,
      'timestamp': timestamp,
      'details': details,
    };
  }
}
