// lib/services/enquiry_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enquiry_model.dart';

class EnquiryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch enquiries by assigned sales person
  Future<List<EnquiryModel>> getEnquiriesByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('enquiries')
          .where('assignedSalesPersonId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => EnquiryModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching enquiries: $e");
      return [];
    }
  }

  // Fetch a single enquiry by enquiryId
  Future<EnquiryModel?> getEnquiryById(String enquiryId) async {
    try {
      DocumentSnapshot doc = await _db.collection('enquiries').doc(enquiryId).get();
      if (doc.exists) {
        return EnquiryModel.fromDocument(doc);
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching enquiry: $e");
      return null;
    }
  }

  // Fetch all enquiries
  Future<List<EnquiryModel>> getEnquiries() async {
    try {
      QuerySnapshot snapshot = await _db.collection('enquiries').get();
      return snapshot.docs.map((doc) => EnquiryModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching enquiries: $e");
      return [];
    }
  }

  // Create a new job enquiry
  Future<void> createJobEnquiry(EnquiryModel enquiry) async {
    try {
      await _db.collection('enquiries').doc(enquiry.enquiryId).set(enquiry.toJson());
    } catch (e) {
      print("Error creating job enquiry: $e");
    }
  }

  // Update an existing enquiry
  Future<void> updateEnquiry(String enquiryId, Map<String, dynamic> data) async {
    try {
      await _db.collection('enquiries').doc(enquiryId).update(data);
    } catch (e) {
      print("Error updating enquiry: $e");
    }
  }

  // Delete an enquiry
  Future<void> deleteEnquiry(String enquiryId) async {
    try {
      await _db.collection('enquiries').doc(enquiryId).delete();
    } catch (e) {
      print("Error deleting enquiry: $e");
    }
  }

  // Fetch all follow-up enquiries (filter by status or any other follow-up criteria)
  Future<List<EnquiryModel>> getFollowUps() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('enquiries')
          .where('status', isEqualTo: 'Pending')
          .get();

      return snapshot.docs.map((doc) => EnquiryModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching follow-ups: $e");
      return [];
    }
  }

  // Update enquiry status
  Future<void> updateEnquiryStatus(String enquiryId, String newStatus) async {
    try {
      await _db.collection('enquiries').doc(enquiryId).update({'status': newStatus});
    } catch (e) {
      print("Error updating enquiry status: $e");
    }
  }

  // Update the follow-up status of an enquiry
  Future<void> updateFollowUpStatus(String enquiryId, String newStatus) async {
    try {
      await _db.collection('enquiries').doc(enquiryId).update({'status': newStatus});
    } catch (e) {
      print("Error updating follow-up status: $e");
    }
  }

  Future<List<EnquiryModel>> getEnquiryNames() async {
    try {
      QuerySnapshot snapshot = await _db.collection('enquiries').get();
      return snapshot.docs.map((doc) => EnquiryModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching enquiry names: $e");
      return [];
    }
  }

  // Add a new enquiry
  Future<void> addEnquiry(EnquiryModel enquiry) async {
    try {
      await _db.collection('enquiries').add(enquiry.toJson());
    } catch (e) {
      print("Error adding enquiry: $e");
    }
  }

  // Assign measurement task to a staff
  Future<void> assignMeasurementTask({
    required String enquiryId,
    required String measurementStaffId,
  }) async {
    final taskId = _db.collection('tasks').doc().id;

    await _db.collection('tasks').doc(taskId).set({
      'taskId': taskId,
      'enquiryId': enquiryId,
      'assignedTo': measurementStaffId,
      'status': 'MTBT',
      'createdAt': Timestamp.now(),
      'dueDate': null,
      'completionDate': null,
      'title': 'Measurement Task',
    });

    await _db.collection('enquiries').doc(enquiryId).update({
      'measurementStaffAssigned': measurementStaffId,
      'taskId': taskId,
      'status': 'MTBT',
    });
  }

  Future<List<EnquiryModel>> getAllEnquiries() async {
    try {
      QuerySnapshot snapshot = await _db.collection('enquiries').get();
      return snapshot.docs.map((doc) => EnquiryModel.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching enquiries: $e");
      return [];
    }
  }
  
  // Copy enquiry data to the sales_order_history collection.
  // This method is called when an enquiry’s status is set to 'Sale done' without extra data.
  Future<void> copyEnquiryToSalesHistory(EnquiryModel enquiry) async {
    final docId = FirebaseFirestore.instance.collection('sales_order_history').doc().id;

    final data = {
      'salesHistoryId': docId,
      'customerName': enquiry.customerName,
      'phoneNumber': enquiry.phoneNumber,
      'productCategory': enquiry.product,
      'createdAt': FieldValue.serverTimestamp(),
      'currentStatus': 'Received all products',
      'statusHistory': [
        {
          'status': 'Received all products',
          // Use client timestamp here because FieldValue.serverTimestamp() is not supported inside arrays.
          'updatedAt': Timestamp.now(),
        }
      ],
      'completed': false,
    };

    await FirebaseFirestore.instance
        .collection('sales_order_history')
        .doc(docId)
        .set(data);
  }

   // New method: Copy enquiry data to sales_order_history with extra fields.
  Future<void> copyEnquiryToSalesHistoryWithExtraData(
      EnquiryModel enquiry, Map<String, Object> extraData) async {
    final docId = FirebaseFirestore.instance.collection('sales_order_history').doc().id;
    final data = {
      'salesHistoryId': docId,
      'customerName': enquiry.customerName,
      'phoneNumber': enquiry.phoneNumber,
      'productCategory': enquiry.product,
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
    data.addAll(extraData);
    await FirebaseFirestore.instance.collection('sales_order_history').doc(docId).set(data);
  }
}
