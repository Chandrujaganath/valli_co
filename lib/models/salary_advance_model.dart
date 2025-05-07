// lib/models/salary_advance_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryAdvanceModel {
  String advanceId;
  String userId;
  String name;
  double amountRequested;
  Timestamp dateSubmitted;
  String status;
  String approvedBy;
  Timestamp? approvalDate;
  String reason;
  String repaymentOption; // 'Single Payment' or 'Part Payment'
  String? repaymentMonth; // For single payment
  String? repaymentFromMonth; // For part payment
  String? repaymentToMonth; // For part payment
  String attachmentUrl;

  SalaryAdvanceModel({
    required this.advanceId,
    required this.userId,
    required this.name,
    required this.amountRequested,
    required this.dateSubmitted,
    required this.status,
    required this.approvedBy,
    this.approvalDate,
    required this.reason,
    required this.repaymentOption,
    this.repaymentMonth,
    this.repaymentFromMonth,
    this.repaymentToMonth,
    required this.attachmentUrl,
  });

  factory SalaryAdvanceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalaryAdvanceModel(
      advanceId: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      amountRequested: (data['amountRequested'] as num?)?.toDouble() ?? 0.0,
      dateSubmitted: data['dateSubmitted'] ?? Timestamp.now(),
      status: data['status'] ?? 'Pending',
      approvedBy: data['approvedBy'] ?? '',
      approvalDate: data['approvalDate'],
      reason: data['reason'] ?? '',
      repaymentOption: data['repaymentOption'] ?? '',
      repaymentMonth: data['repaymentMonth'],
      repaymentFromMonth: data['repaymentFromMonth'],
      repaymentToMonth: data['repaymentToMonth'],
      attachmentUrl: data['attachmentUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'amountRequested': amountRequested,
      'dateSubmitted': dateSubmitted,
      'status': status,
      'approvedBy': approvedBy,
      'approvalDate': approvalDate,
      'reason': reason,
      'repaymentOption': repaymentOption,
      'repaymentMonth': repaymentMonth,
      'repaymentFromMonth': repaymentFromMonth,
      'repaymentToMonth': repaymentToMonth,
      'attachmentUrl': attachmentUrl,
    };
  }
}
