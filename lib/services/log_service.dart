// lib/services/log_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/log_model.dart';

class LogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new log entry
  Future<void> addLog({
    required String action,
    required String description,
  }) async {
    try {
      String userId = _auth.currentUser?.uid ?? "unknown_user";
      await _db.collection('logs').add({
        'userId': userId,
        'action': action,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding log: $e");
    }
  }

  // Fetch logs for a specific user as List<LogModel>
  Future<List<LogModel>> getUserLogs(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => LogModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching user logs: $e");
      return [];
    }
  }

  // Fetch all logs as List<LogModel>, with optional limit
  Future<List<LogModel>> getAllLogs({int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => LogModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching logs: $e");
      return [];
    }
  }

  // General method to fetch logs (combines user-specific and all logs) as List<LogModel>
  Future<List<LogModel>> getLogs({String? userId, int limit = 50}) async {
    try {
      Query query = _db.collection('logs').orderBy('timestamp', descending: true);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      QuerySnapshot snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => LogModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching logs: $e");
      return [];
    }
  }
}
