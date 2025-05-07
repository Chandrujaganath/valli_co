// lib/services/sales_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/sales_model.dart';

class SalesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch a single sale by its saleId.
  Future<SalesModel?> getSaleById(String saleId) async {
    try {
      DocumentSnapshot doc = await _db.collection('sales').doc(saleId).get();
      if (doc.exists) {
        return SalesModel.fromDocument(doc);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching sale: $e");
      return null;
    }
  }

  /// Fetch all sales, ordered by salesDate descending.
  Future<List<SalesModel>> getSales() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('sales')
          .orderBy('salesDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => SalesModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching sales: $e");
      return [];
    }
  }

  /// Save a complete sale record.
  Future<void> saveSalesData(SalesModel sale) async {
    try {
      await _db.collection('sales').doc(sale.saleId).set(sale.toJson());
    } catch (e) {
      print("Error saving sales data: $e");
      throw Exception("Failed to save sales data");
    }
  }

  /// Update an existing sale.
  Future<void> updateSale(String saleId, Map<String, dynamic> data) async {
    try {
      await _db.collection('sales').doc(saleId).update(data);
    } catch (e) {
      print("Error updating sale: $e");
      throw Exception("Failed to update sale");
    }
  }

  /// Delete a sale.
  Future<void> deleteSale(String saleId) async {
    try {
      await _db.collection('sales').doc(saleId).delete();
    } catch (e) {
      print("Error deleting sale: $e");
      throw Exception("Failed to delete sale");
    }
  }

  /// Fetch the last entry date for a user.
  Future<DateTime?> getLastEntryDateForUser(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('sales')
          .where('assignedSalesPersonId', isEqualTo: userId)
          .orderBy('entryDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        Timestamp ts = snapshot.docs.first['entryDate'];
        return ts.toDate();
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching last entry date: $e");
      return null;
    }
  }

  /// Fetch sales by customer.
  Future<List<SalesModel>> getSalesByCustomer(String customerId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('sales')
          .where('customerId', isEqualTo: customerId)
          .orderBy('salesDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => SalesModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching sales for customer $customerId: $e");
      rethrow;
    }
  }

  /// Fetch sales for a specific user.
  Future<List<SalesModel>> getSalesByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('sales')
          .where('assignedSalesPersonId', isEqualTo: userId)
          .orderBy('salesDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => SalesModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching sales for user $userId: $e");
      rethrow;
    }
  }

  /// Update the sales status.
  Future<void> updateSalesStatus(String saleId, String newStatus) async {
    try {
      await _db.collection('sales').doc(saleId).update({
        'salesStatus': newStatus,
        'isCompleted': newStatus == 'Payment Done',
      });
    } catch (e) {
      print("Error updating sales status: $e");
      rethrow;
    }
  }

  /// Update sales status along with TAT status.
  Future<void> updateSalesStatusAndTatStatus(
      String saleId, String newSalesStatus, String newTatStatus) async {
    try {
      await _db.collection('sales').doc(saleId).update({
        'salesStatus': newSalesStatus,
        'tatStatus': newTatStatus,
        'isCompleted': newSalesStatus == 'Payment Done',
      });
    } catch (e) {
      print("Error updating sales and TAT status: $e");
      rethrow;
    }
  }

  /// Save minimal sales data from the Sales Data Entry form.
  /// Now supports an optional 'additionalNotes' field.
  /// Also, it now saves an 'entryDate' field.
  Future<void> saveMinimalSalesData(String docId, Map<String, dynamic> data) async {
    try {
      // Ensure required date fields are not null.
      if (data['salesDate'] == null) {
        throw Exception("salesDate is null. Please select a Cash Sales Date.");
      }
      if (data['tatDate'] == null) {
        throw Exception("tatDate is null. Please select a TAT Date.");
      }
      if (data['createdAt'] == null) {
        throw Exception("createdAt is null. Please contact support.");
      }

      // Convert fields to Timestamp if needed.
      Timestamp salesTimestamp;
      if (data['salesDate'] is DateTime) {
        salesTimestamp = Timestamp.fromDate(data['salesDate'] as DateTime);
      } else if (data['salesDate'] is Timestamp) {
        salesTimestamp = data['salesDate'] as Timestamp;
      } else {
        throw Exception("Invalid type for salesDate");
      }

      Timestamp tatTimestamp;
      if (data['tatDate'] is DateTime) {
        tatTimestamp = Timestamp.fromDate(data['tatDate'] as DateTime);
      } else if (data['tatDate'] is Timestamp) {
        tatTimestamp = data['tatDate'] as Timestamp;
      } else {
        throw Exception("Invalid type for tatDate");
      }

      Timestamp createdAtTimestamp;
      if (data['createdAt'] is DateTime) {
        createdAtTimestamp = Timestamp.fromDate(data['createdAt'] as DateTime);
      } else if (data['createdAt'] is Timestamp) {
        createdAtTimestamp = data['createdAt'] as Timestamp;
      } else {
        throw Exception("Invalid type for createdAt");
      }

      // Add an entryDate field (for record-keeping).
      final entryDateTimestamp = Timestamp.fromDate(DateTime.now());

      final dbDoc = {
        ...data,
        'salesDate': salesTimestamp,
        'tatDate': tatTimestamp,
        'createdAt': createdAtTimestamp,
        'entryDate': entryDateTimestamp,
      };

     debugPrint("Saving doc $docId with data: $dbDoc");
    await _db.collection('sales').doc(docId).set(dbDoc);
  } catch (e, stack) {
    debugPrint('Error in saveMinimalSalesData: $e');
    debugPrint('Stack trace:\n$stack');
    rethrow; // If you want the caller to see the error too
  }
}
}
