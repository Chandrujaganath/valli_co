// lib/services/sales_history_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SalesHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'sales_order_history';

  // Copy sale data from an enquiry (if you prefer to pass a map)
  // Alternatively, the EnquiryService already performs the copy.
  Future<void> copySaleFromEnquiry(Map<String, dynamic> saleData) async {
    final docId = _db.collection(collectionPath).doc().id;
    final data = {
      'salesHistoryId': docId,
      'customerName': saleData['customerName'],
      'phoneNumber': saleData['phoneNumber'],
      'productCategory': saleData['productCategory'] ?? saleData['product'],
      'createdAt': FieldValue.serverTimestamp(),
      'currentStatus': 'Received all products',
      'statusHistory': [
        {
          'status': 'Received all products',
          'updatedAt': Timestamp.now(),
        }
      ],
      'completed': false,
    };

    await _db.collection(collectionPath).doc(docId).set(data);
  }

 // Retrieve the entire sales order history with optional sorting and filtering.
  Future<List<Map<String, dynamic>>> getSalesHistory({
    String? sortBy,
    bool descending = true,
    String? searchQuery,
  }) async {
    Query query = _db.collection(collectionPath);

    if (sortBy != null) {
      query = query.orderBy(sortBy, descending: descending);
    } else {
      query = query.orderBy('createdAt', descending: descending);
    }

    QuerySnapshot snapshot = await query.get();
    List<Map<String, dynamic>> docs = snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['docId'] = d.id;
      return data;
    }).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      docs = docs.where((doc) {
        final customerName = (doc['customerName'] ?? '').toString().toLowerCase();
        return customerName.contains(searchQuery.toLowerCase());
      }).toList();
    }
    return docs;
  }

  // Update the status for a sales order history entry.
  Future<void> updateSaleHistoryStatus(String docId, String newStatus) async {
    final now = Timestamp.now();
    final newEntry = {'status': newStatus, 'updatedAt': now};

    await _db.collection(collectionPath).doc(docId).update({
      'currentStatus': newStatus,
      'statusHistory': FieldValue.arrayUnion([newEntry]),
      'completed': newStatus == 'Payment Done',
    });
  }
}
