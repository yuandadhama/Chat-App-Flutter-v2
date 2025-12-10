import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_daily_planner/services/auth/auth_service.dart';
import 'package:smart_daily_planner/services/friend_service.dart';

class FriendRequestsPage extends StatelessWidget {
  FriendRequestsPage({super.key});

  final FriendService _friendService = FriendService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUID = _auth.getCurrentUser()!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _friendService.getIncomingRequests(currentUID),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No incoming requests"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final request = docs[i];
              final data = request.data() as Map<String, dynamic>;

              final fromUID = data["from"];
              final requestId = request.id;

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(fromUID)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final userData = userSnap.data!.data()!;
                  final email = userData["email"];

                  return ListTile(
                    title: Text(email),
                    subtitle: const Text("Sent you a friend request"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ACCEPT
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await _friendService.acceptRequest(
                                requestId, fromUID, currentUID);
                          },
                        ),
                        // REJECT
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await _friendService.rejectRequest(requestId);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
