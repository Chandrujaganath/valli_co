// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createDocument(String collectionPath, Map<String, dynamic> data) async {
    await _db.collection(collectionPath).add(data);
  }

  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    await _db.collection(collectionPath).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collectionPath, String docId) async {
    await _db.collection(collectionPath).doc(docId).delete();
  }

  Stream<QuerySnapshot> getCollectionStream(String collectionPath) {
    return _db.collection(collectionPath).snapshots();
  }

  Future<DocumentSnapshot> getDocument(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId).get();
  }
}
