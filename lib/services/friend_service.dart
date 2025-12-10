import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send friend request
  Future<void> sendFriendRequest(String fromUID, String toUID) async {
    await _firestore.collection("FriendRequests").add({
      "from": fromUID,
      "to": toUID,
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // Get friend request status (Future — ringan)
  Future<String> getStatus(String fromUID, String toUID) async {
    final snap = await _firestore
        .collection("FriendRequests")
        .where("from", isEqualTo: fromUID)
        .where("to", isEqualTo: toUID)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return "none";
    return snap.docs.first["status"];
  }

  // Get list of incoming requests (stream)
  Stream<QuerySnapshot> getIncomingRequests(String currentUID) {
    return _firestore
        .collection("FriendRequests")
        .where("to", isEqualTo: currentUID)
        .where("status", isEqualTo: "pending")
        .snapshots();
  }

  // Accept friend request
  Future<void> acceptRequest(
      String requestId, String fromUID, String toUID) async {
    final batch = _firestore.batch();

    // Get the toUser's email to use as default name
    final toUserDoc = await _firestore.collection("Users").doc(toUID).get();
    final toUserEmail = toUserDoc.data()?["email"] ?? "Friend";

    final fromUserDoc = await _firestore.collection("Users").doc(fromUID).get();
    final fromUserEmail = fromUserDoc.data()?["email"] ?? "Friend";

    // Add friend to fromUID's friends subcollection
    final friendDoc1 = _firestore
        .collection("Users")
        .doc(fromUID)
        .collection("friends")
        .doc(toUID);
    batch.set(friendDoc1, {
      "friendUID": toUID,
      "friendName": toUserEmail,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // Add friend to toUID's friends subcollection
    final friendDoc2 = _firestore
        .collection("Users")
        .doc(toUID)
        .collection("friends")
        .doc(fromUID);
    batch.set(friendDoc2, {
      "friendUID": fromUID,
      "friendName": fromUserEmail,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // Update request
    final reqDoc = _firestore.collection("FriendRequests").doc(requestId);
    batch.update(reqDoc, {"status": "accepted"});

    await batch.commit();
  }

  // Reject friend request
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection("FriendRequests").doc(requestId).update({
      "status": "rejected",
    });
  }

  // Get list of friends (stream)
  Stream<QuerySnapshot> getFriends(String currentUID) {
    return _firestore
        .collection("Users")
        .doc(currentUID)
        .collection("friends")
        .snapshots();
  }

  // Get friend UID (helper method)
  Future<String?> getFriendUID(String currentUID, String friendDocId) async {
    final doc = await _firestore
        .collection("Users")
        .doc(currentUID)
        .collection("friends")
        .doc(friendDocId)
        .get();

    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return data["friendUID"];
  }

  // Check if two users are already friends
  Future<bool> isFriends(String currentUID, String otherUID) async {
    final doc = await _firestore
        .collection("Users")
        .doc(currentUID)
        .collection("friends")
        .doc(otherUID)
        .get();

    return doc.exists;
  }

  // Remove friendship between two users (delete from both friends subcollections)
  Future<void> removeFriend(String currentUID, String otherUID) async {
    final batch = _firestore.batch();

    // Remove from currentUID's friends
    final doc1 = _firestore
        .collection("Users")
        .doc(currentUID)
        .collection("friends")
        .doc(otherUID);
    batch.delete(doc1);

    // Remove from otherUID's friends
    final doc2 = _firestore
        .collection("Users")
        .doc(otherUID)
        .collection("friends")
        .doc(currentUID);
    batch.delete(doc2);

    await batch.commit();
  }

  // Update friend's custom name
  Future<void> updateFriendName(
      String currentUID, String friendUID, String newName) async {
    await _firestore
        .collection("Users")
        .doc(currentUID)
        .collection("friends")
        .doc(friendUID)
        .update({"friendName": newName});
  }
}
