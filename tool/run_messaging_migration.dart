import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  final db = FirebaseFirestore.instance;

  print(
      'Starting migration: Ensuring all chat documents have lastMessageTimestamp...');

  final chats = await db.collection('chats').get();
  final batch = db.batch();
  int updated = 0;
  for (var doc in chats.docs) {
    final data = doc.data();
    if (!data.containsKey('lastMessageTimestamp') ||
        data['lastMessageTimestamp'] == null) {
      batch.update(doc.reference, {
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      updated++;
    }
  }
  if (updated > 0) {
    await batch.commit();
    print('Migration complete. Updated $updated chat documents.');
  } else {
    print('No chat documents needed updating.');
  }
}
