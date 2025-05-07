// lib/services/measurement_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class MeasurementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get assigned tasks with status 'MTBT'
  Stream<List<TaskModel>> getAssignedTasks(String status, String userId) {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: status)
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromDocument(doc))
            .toList());
  }

  // Stream to get completed tasks with status 'MOK'
  Stream<List<TaskModel>> getCompletedTasks(String status, String userId) {
    return _firestore
        .collection('tasks')
        .where('status', isEqualTo: status)
        .where('assignedTo', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromDocument(doc))
            .toList());
  }

  // Function to update a task to 'MOK' and sync with the associated enquiry
  Future<void> updateTaskAndEnquiryToMOK({
    required String taskId,
    required String product,
    required String crNumber,
    required DateTime? measurementDate,
    required String remarks,
    required int tat,
  }) async {
    final batch = _firestore.batch();

    // Update the task document to 'MOK'
    final taskRef = _firestore.collection('tasks').doc(taskId);
    batch.update(taskRef, {
      'status': 'MOK',
      'product': product,
      'crNumber': crNumber,
      'measurementDate': measurementDate != null ? Timestamp.fromDate(measurementDate) : null,
      'remarks': remarks,
      'tat': tat,
      'completionDate': Timestamp.now(),
    });

    // Find associated enquiry and update its status to 'MOK'
    final enquiryQuery = await _firestore
        .collection('enquiries')
        .where('taskId', isEqualTo: taskId)
        .get();

    for (var enquiryDoc in enquiryQuery.docs) {
      batch.update(enquiryDoc.reference, {'status': 'MOK'});
    }

    await batch.commit();
  }

  // Revert task status to 'Follow-up' upon rejection
  Future<void> rejectTaskToFollowUp({required String taskId}) async {
    final batch = _firestore.batch();

    final taskRef = _firestore.collection('tasks').doc(taskId);
    batch.update(taskRef, {
      'status': 'Rejected',
      'completionDate': Timestamp.now(),
    });

    // Find associated enquiry and revert to 'Follow-up'
    final enquiryQuery = await _firestore
        .collection('enquiries')
        .where('taskId', isEqualTo: taskId)
        .get();

    for (var enquiryDoc in enquiryQuery.docs) {
      batch.update(enquiryDoc.reference, {'status': 'Follow-up'});
    }

    await batch.commit();
  }

  // Get TAT tracking for tasks, returns a list of tasks with turnaround times
  Stream<List<TaskModel>> getTATTaskTracking() {
    return _firestore
        .collection('tasks')
        .where('status', whereIn: ['MTBT', 'MOK'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromDocument(doc))
            .toList());
  }

  // Get all measurement tasks
  Stream<List<TaskModel>> getMeasurements() {
    return _firestore
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromDocument(doc))
            .toList());
  }

  /// Fetch completed tasks with pagination
  Future<List<TaskModel>> getCompletedTasksPaginated({
    required String status,
    required String userId,
    required int offset,
    required int limit,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: status)
          .where('assignedTo', isEqualTo: userId)
          .orderBy('measurementDate', descending: true)
          .startAfter([offset])
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromDocument(doc))
          .toList();
    } catch (e) {
      // Error handling (if needed, consider logging this error using your logging strategy)
      rethrow;
    }
  }
}
