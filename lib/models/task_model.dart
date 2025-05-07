// lib/models/task_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String enquiryId;
  final String assignedTo;
  final String status;
  final Timestamp createdAt;
  final Timestamp? dueDate;
  final Timestamp? completionDate;
  final String title;
  final String? product;
  final String? crNumber;
  final Timestamp? measurementDate;
  final String? remarks;
  final int? tat;

  TaskModel({
    required this.taskId,
    required this.enquiryId,
    required this.assignedTo,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.completionDate,
    required this.title,
    this.product,
    this.crNumber,
    this.measurementDate,
    this.remarks,
    this.tat,
  });

  factory TaskModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      taskId: data['taskId'] ?? '',
      enquiryId: data['enquiryId'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      status: data['status'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      dueDate: data['dueDate'],
      completionDate: data['completionDate'],
      title: data['title'] ?? '',
      product: data['product'],
      crNumber: data['crNumber'],
      measurementDate: data['measurementDate'],
      remarks: data['remarks'],
      tat: data['tat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'enquiryId': enquiryId,
      'assignedTo': assignedTo,
      'status': status,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'completionDate': completionDate,
      'title': title,
      'product': product,
      'crNumber': crNumber,
      'measurementDate': measurementDate,
      'remarks': remarks,
      'tat': tat,
    };
  }
}
