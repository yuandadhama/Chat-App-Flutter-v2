import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------
  // GET ALL USERS (untuk friendlist)
  // ---------------------------
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) => doc.data()).toList();
      print("Fetched ${users.length} users");
      return users;
    });
  }

  // ---------------------------
  // REALTIME SEARCH USERS (prefix search)
  // ---------------------------
  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection("Users")
        .where("email", isGreaterThanOrEqualTo: query)
        .where("email", isLessThanOrEqualTo: "$query\uf8ff")
        .snapshots();
  }

  // ---------------------------
  // SEND MESSAGE
  // ---------------------------
  Future<void> sendMessage(String receiverID, message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // ---------------------------
  // GET CHAT MESSAGES
  // ---------------------------
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
