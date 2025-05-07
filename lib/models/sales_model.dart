// lib/models/sales_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SalesModel {
  final String saleId;
  final DateTime salesDate; // New field replacing the previous salesDate.
  final double totalCashSales;
  final int numberOfCashSales;
  final String crNumbers;
  final String customerName;
  final String customerId;
  final double crAmount;
  final String productCategory;
  final DateTime tatDate;
  final String createdBy;
  final DateTime createdAt;
  final String? additionalNotes; // New optional field
  
  // The following fields are retained for backward compatibility or extended functionality.
  final String saleType; // Default: 'Cash'
  final String salesStatus; // Default: 'Received all products'
  final String tatStatus; // Default: 'Pending'
  final bool isCompleted; // Default: false
  final String assignedSalesPerson;
  final String assignedSalesPersonId;
  final String remarks;
  final List<Map<String, dynamic>> productsSold;
  final DateTime entryDate; // For record-keeping; default to createdAt if not provided

  SalesModel({
    required this.saleId,
    required this.salesDate,
    required this.totalCashSales,
    required this.numberOfCashSales,
    required this.crNumbers,
    required this.customerName,
    required this.customerId,
    required this.crAmount,
    required this.productCategory,
    required this.tatDate,
    required this.createdBy,
    required this.createdAt,
    this.additionalNotes,
    this.saleType = 'Cash',
    this.salesStatus = 'Received all products',
    this.tatStatus = 'Pending',
    this.isCompleted = false,
    this.assignedSalesPerson = '',
    this.assignedSalesPersonId = '',
    this.remarks = '',
    this.productsSold = const [],
    DateTime? entryDate,
  }) : entryDate = entryDate ?? createdAt;

  // Factory method to create a SalesModel instance from a Firestore document.
  factory SalesModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesModel(
      saleId: doc.id,
      salesDate: (data['salesDate'] as Timestamp).toDate(),
      totalCashSales: (data['totalCashSales'] ?? 0).toDouble(),
      numberOfCashSales: data['numberOfCashSales'] ?? 0,
      crNumbers: data['crNumbers'] ?? '',
      customerName: data['customerName'] ?? '',
      customerId: data['customerId'] ?? '',
      crAmount: (data['crAmount'] ?? 0).toDouble(),
      productCategory: data['productCategory'] ?? '',
      tatDate: (data['tatDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      additionalNotes: data['additionalNotes'],
      saleType: data['saleType'] ?? 'Cash',
      salesStatus: data['salesStatus'] ?? 'Received all products',
      tatStatus: data['tatStatus'] ?? 'Pending',
      isCompleted: data['isCompleted'] ?? false,
      assignedSalesPerson: data['assignedSalesPerson'] ?? '',
      assignedSalesPersonId: data['assignedSalesPersonId'] ?? '',
      remarks: data['remarks'] ?? '',
      productsSold: List<Map<String, dynamic>>.from(data['productsSold'] ?? []),
      entryDate: (data['entryDate'] as Timestamp).toDate(),
    );
  }

  // Convert SalesModel instance to a JSON-compatible map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'salesDate': salesDate,
      'totalCashSales': totalCashSales,
      'numberOfCashSales': numberOfCashSales,
      'crNumbers': crNumbers,
      'customerName': customerName,
      'customerId': customerId,
      'crAmount': crAmount,
      'productCategory': productCategory,
      'tatDate': tatDate,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'additionalNotes': additionalNotes,
      'saleType': saleType,
      'salesStatus': salesStatus,
      'tatStatus': tatStatus,
      'isCompleted': isCompleted,
      'assignedSalesPerson': assignedSalesPerson,
      'assignedSalesPersonId': assignedSalesPersonId,
      'remarks': remarks,
      'productsSold': productsSold,
      'entryDate': Timestamp.fromDate(entryDate),
    };
  }
}
