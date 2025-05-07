import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendMessage(
      String chatId, Map<String, dynamic> messageData) async {
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update the last message in the chat document
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': messageData,
        'lastMessageTimestamp':
            messageData['timestamp'] ?? FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<String> getChatId(String userId, String peerId) async {
    final chatsRef = _db.collection('chats');
    final chatQuery =
        await chatsRef.where('participants', arrayContains: userId).get();
    for (var doc in chatQuery.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(peerId)) {
        return doc.id;
      }
    }
    final chatDoc = await chatsRef.add({
      'participants': [userId, peerId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
    return chatDoc.id;
  }

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getLastMessage(String chatId) async {
    try {
      // First try to get the last message from the chat document
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      if (chatDoc.exists &&
          chatDoc.data()?.containsKey('lastMessage') == true) {
        return chatDoc.data()?['lastMessage'] as Map<String, dynamic>;
      }

      // If not available in the chat document, get the last message from the messages collection
      final messagesQuery = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        return messagesQuery.docs.first.data();
      }

      return null;
    } catch (e) {
      print('Error getting last message: $e');
      return null;
    }
  }

  Future<void> deleteMessageForBoth(String chatId, String messageId) async {
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'deleted': true, 'text': ''});
    } catch (e) {
      throw Exception('Error deleting message for both: $e');
    }
  }

  Future<void> deleteMessageForSenderOnly(
      String chatId, String messageId, String senderId) async {
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deletedFor': FieldValue.arrayUnion([senderId])
      });
    } catch (e) {
      throw Exception('Error deleting message for sender: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Get unread messages for this user
      final unreadMessages = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .get();

      // Update each message to mark as read
      final batch = _db.batch();
      for (var doc in unreadMessages.docs) {
        final data = doc.data();
        List<dynamic> readBy = data['readBy'] ?? [];

        // Only update if not already read by this user
        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// One-time migration: Ensure all chat documents have a lastMessageTimestamp field
  Future<void> ensureAllChatsHaveTimestamps() async {
    final chats = await _db.collection('chats').get();
    final batch = _db.batch();
    for (var doc in chats.docs) {
      final data = doc.data();
      if (!data.containsKey('lastMessageTimestamp') ||
          data['lastMessageTimestamp'] == null) {
        batch.update(doc.reference, {
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }
}
