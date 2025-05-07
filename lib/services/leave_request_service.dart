// lib/services/leave_request_service.dart

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_request_model.dart';
import '../utils/constants.dart';

class LeaveRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all leave requests for admin/manager view
  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .orderBy('dateSubmitted', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveRequestModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching leave requests: $e');
      throw Exception('Failed to fetch leave requests');
    }
  }

  // Fetch only pending leave requests for admin/manager view
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

  // Fetch approved leave requests for a specific user
  Future<List<LeaveRequestModel>> getApprovedLeaveRequestsForUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(FirestoreCollections.leaveRequests)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: Statuses.approved) // Ensure only approved leaves
          .get();

      return snapshot.docs
          .map((doc) => LeaveRequestModel.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching approved leave requests for user: $e');
      return [];
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

  // Fetch user leave requests in real-time for live status updates
  Stream<List<LeaveRequestModel>> getUserLeaveRequests(String userId) {
    return _firestore
        .collection(FirestoreCollections.leaveRequests)
        .where('userId', isEqualTo: userId)
        .orderBy('dateSubmitted', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequestModel.fromDocument(doc))
            .toList());
  }

  // Submit a new leave request
  Future<void> submitLeaveRequest({
    required String userId,
    required String name,
    required String leaveType,
    required Timestamp startDate,
    required Timestamp endDate,
    required String dayType,
    required String reason,
  }) async {
    try {
      final newRequest = {
        'userId': userId,
        'name': name,
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        'dayType': dayType,
        'reason': reason,
        'status': Statuses.pending,
        'dateSubmitted': Timestamp.now(),
      };

      await _firestore.collection(FirestoreCollections.leaveRequests).add(newRequest);
    } catch (e) {
      print('Error submitting leave request: $e');
      throw Exception('Failed to submit leave request');
    }
  }

  // Update leave request status
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
}
