// lib/models/enquiry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryModel {
  final String enquiryId;
  final String enquiryName;
  final String customerId;
  final String customerName;
  final String phoneNumber;
  final String customerEmail;
  final String customerAddress;
  final String region;
  final String product; // Now represents product category
  final String assignedSalesPerson;
  final String assignedSalesPersonId;
  final int numMaleCustomers;
  final int numFemaleCustomers;
  final int numChildrenCustomers;
  final String status;
  final String remarks;
  final Timestamp enquiryDate;
  final Timestamp timeIn;
  final Timestamp? timeOut;
  final String? assignedMeasurementStaff;
  final String specificProductScene; // Newly added field

  EnquiryModel({
    required this.enquiryId,
    required this.enquiryName,
    required this.customerId,
    required this.customerName,
    required this.phoneNumber,
    required this.customerEmail,
    required this.customerAddress,
    required this.region,
    required this.product,
    required this.assignedSalesPerson,
    required this.assignedSalesPersonId,
    required this.numMaleCustomers,
    required this.numFemaleCustomers,
    required this.numChildrenCustomers,
    required this.status,
    required this.remarks,
    required this.enquiryDate,
    required this.timeIn,
    this.timeOut,
    this.assignedMeasurementStaff,
    required this.specificProductScene,
  });

  factory EnquiryModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EnquiryModel(
      enquiryId: data['enquiryId'] ?? '',
      enquiryName: data['enquiryName'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      region: data['region'] ?? '',
      product: data['product'] ?? '',
      assignedSalesPerson: data['assignedSalesPerson'] ?? '',
      assignedSalesPersonId: data['assignedSalesPersonId'] ?? '',
      numMaleCustomers: data['numMaleCustomers'] ?? 0,
      numFemaleCustomers: data['numFemaleCustomers'] ?? 0,
      numChildrenCustomers: data['numChildrenCustomers'] ?? 0,
      status: data['status'] ?? '',
      remarks: data['remarks'] ?? '',
      enquiryDate: data['enquiryDate'] ?? Timestamp.now(),
      timeIn: data['timeIn'] ?? Timestamp.now(),
      timeOut: data['timeOut'],
      assignedMeasurementStaff: data['assignedMeasurementStaff'],
      specificProductScene: data['specificProductScene'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enquiryId': enquiryId,
      'enquiryName': enquiryName,
      'customerId': customerId,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
      'region': region,
      'product': product,
      'assignedSalesPerson': assignedSalesPerson,
      'assignedSalesPersonId': assignedSalesPersonId,
      'numMaleCustomers': numMaleCustomers,
      'numFemaleCustomers': numFemaleCustomers,
      'numChildrenCustomers': numChildrenCustomers,
      'status': status,
      'remarks': remarks,
      'enquiryDate': enquiryDate,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'assignedMeasurementStaff': assignedMeasurementStaff,
      'specificProductScene': specificProductScene,
    };
  }
}
