// lib/models/measurement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementModel {
  final String measurementId;
  final String product;
  final String crNumber;
  final String assignedStaff;
  final String jobStatus; // 'MTBT' or 'MOK'
  final String remarks;
  final Timestamp tatStartDate;
  final Timestamp expectedCompletionDate;
  final Timestamp actualCompletionDate;
  final String tatStatus; // 'On Time', 'Delayed', 'Pending'
  final bool isCompleted;

  MeasurementModel({
    required this.measurementId,
    required this.product,
    required this.crNumber,
    required this.assignedStaff,
    required this.jobStatus,
    required this.remarks,
    required this.tatStartDate,
    required this.expectedCompletionDate,
    required this.actualCompletionDate,
    required this.tatStatus,
    required this.isCompleted,
  });

  // Convert Firestore document to MeasurementModel
  factory MeasurementModel.fromDocument(DocumentSnapshot doc) {
    return MeasurementModel(
      measurementId: doc['measurementId'] ?? '',
      product: doc['product'] ?? '',
      crNumber: doc['crNumber'] ?? '',
      assignedStaff: doc['assignedStaff'] ?? '',
      jobStatus: doc['jobStatus'] ?? 'MTBT',
      remarks: doc['remarks'] ?? '',
      tatStartDate: doc['tatStartDate'] ?? Timestamp.now(),
      expectedCompletionDate: doc['expectedCompletionDate'] ?? Timestamp.now(),
      actualCompletionDate: doc['actualCompletionDate'] ?? Timestamp.now(),
      tatStatus: doc['tatStatus'] ?? 'Pending',
      isCompleted: doc['isCompleted'] ?? false,
    );
  }

  // Convert MeasurementModel to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'measurementId': measurementId,
      'product': product,
      'crNumber': crNumber,
      'assignedStaff': assignedStaff,
      'jobStatus': jobStatus,
      'remarks': remarks,
      'tatStartDate': tatStartDate,
      'expectedCompletionDate': expectedCompletionDate,
      'actualCompletionDate': actualCompletionDate,
      'tatStatus': tatStatus,
      'isCompleted': isCompleted,
    };
  }
}
