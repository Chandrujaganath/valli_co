// lib/services/leave_management_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_request_model.dart';
import '../utils/constants.dart';

class LeaveManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch pending leave requests
  Future<List<LeaveRequestModel>> getPendingLeaveRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .where('status', isEqualTo: Statuses.pending)
          .orderBy('dateSubmitted', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveRequestModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching pending leave requests: $e');
      throw Exception('Failed to fetch pending leave requests');
    }
  }

  // Update leave request status (Approve/Reject)
  Future<void> updateLeaveRequestStatus(String leaveId, String newStatus) async {
    try {
      await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .doc(leaveId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating leave request status: $e');
      throw Exception('Failed to update leave request status');
    }
  }

  // Fetch leave requests for a specific date
  Future<List<LeaveRequestModel>> getLeaveRequestsForDate(DateTime? date) async {
    if (date == null) return [];

    try {
      final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
      final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));

      QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .where('startDate', isLessThanOrEqualTo: endOfDay)
          .where('endDate', isGreaterThanOrEqualTo: startOfDay)
          .orderBy('dateSubmitted', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveRequestModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leave requests for date: $e');
      throw Exception('Failed to fetch leave requests for date');
    }
  }

  /// Check if a user is on approved leave for a given date
  Future<bool> isUserOnApprovedLeaveForDate(String userId, DateTime date) async {
    final startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0));
    final endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: Statuses.approved)
          .where('startDate', isLessThanOrEqualTo: endOfDay)
          .where('endDate', isGreaterThanOrEqualTo: startOfDay)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking leave for user: $e');
      return false;
    }
  }

  // Get all approved leaves for a user for a given month
  Future<List<LeaveRequestModel>> getApprovedLeavesForUserForMonth(String userId, int year, int month) async {
    // month range
    DateTime start = DateTime(year, month, 1);
    DateTime end = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);

    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: Statuses.approved)
          .where('startDate', isLessThanOrEqualTo: endTs)
          .where('endDate', isGreaterThanOrEqualTo: startTs)
          .get();

      return snapshot.docs.map((doc) => LeaveRequestModel.fromDocument(doc)).toList();
    } catch (e) {
      print('Error fetching approved leaves for month: $e');
      return [];
    }
  }
}
