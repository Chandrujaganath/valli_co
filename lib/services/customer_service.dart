// lib/services/customer_service.dart

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _db.collection('customers').add(customer.toJson());
    } catch (e) {
      print("Error adding customer: $e");
      rethrow;
    }
  }

  Future<List<CustomerModel>> getAllCustomersOnce() async {
    try {
      QuerySnapshot snapshot = await _db.collection('customers').get();
      return snapshot.docs.map((doc) => CustomerModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching customers: $e");
      rethrow;
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _db.collection('customers').doc(customer.customerId).update(customer.toJson());
    } catch (e) {
      print("Error updating customer: $e");
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _db.collection('customers').doc(customerId).delete();
    } catch (e) {
      print("Error deleting customer: $e");
      rethrow;
    }
  }

  // Real-time stream of customers
  Stream<List<CustomerModel>> streamCustomers() {
    try {
      return _db.collection('customers').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => CustomerModel.fromDocument(doc)).toList());
    } catch (e) {
      print("Error streaming customers: $e");
      rethrow;
    }
  }
  Future<CustomerModel?> getCustomerById(String customerId) async {
  try {
    final doc = await _db.collection('customers').doc(customerId).get();
    if (doc.exists) {
      return CustomerModel.fromDocument(doc);
    } else {
      return null;
    }
  } catch (e) {
    print("Error fetching customer by ID: $e");
    rethrow;
  }
}
}
