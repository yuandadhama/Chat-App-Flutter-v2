import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_daily_planner/components/my_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_daily_planner/services/friend_service.dart';
import 'package:smart_daily_planner/pages/chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  String query = "";

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  query = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search user by email...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Show search results or friends list
            if (query.isEmpty)
              Expanded(
                child: currentUser == null
                    ? const Center(child: Text("Please log in"))
                    : Column(
                        children: [
                          // Friends Header
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Friends",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Friends List
                          Expanded(
                            child: _buildFriendsList(currentUser.uid),
                          ),
                        ],
                      ),
              )
            else
              Expanded(
                child: currentUser == null
                    ? const Center(child: Text("Please log in"))
                    : _buildSearchResults(currentUser.uid),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(String currentUID) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: "$query\uf8ff")
          .snapshots(),
      builder: (context, snapshot) {
        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ERROR
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // TIDAK ADA DATA
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        final allUsers = snapshot.data!.docs;

        // Filter out current user
        final filteredUsers = allUsers.where((userDoc) {
          return userDoc.id != currentUID;
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("No other users found"));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final user = userDoc.data() as Map<String, dynamic>;
            final email = user['email'] ?? 'No email';
            final userId = userDoc.id;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(email),
                trailing: _buildFriendButton(userId, currentUID),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendButton(String toUID, String currentUID) {
    return FutureBuilder<String>(
      future: _getFriendButtonStatus(currentUID, toUID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final status = snapshot.data ?? "none";
        final isPending = status == "pending";
        final isFriends = status == "friends";
        final isRejected = status == "rejected";

        return ElevatedButton(
          onPressed: (isPending || isFriends || isRejected)
              ? null
              : () => _sendFriendRequest(currentUID, toUID),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFriends
                ? Colors.green
                : isRejected
                    ? Colors.red
                    : isPending
                        ? Colors.grey
                        : Colors.blue,
            disabledBackgroundColor: isFriends
                ? Colors.green
                : isRejected
                    ? Colors.red
                    : Colors.grey,
          ),
          child: Text(
            isFriends
                ? "Already Friends"
                : isRejected
                    ? "Rejected"
                    : isPending
                        ? "Requested"
                        : "Add Friend",
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Future<String> _getFriendButtonStatus(String currentUID, String toUID) async {
    // Check if already friends
    final isFriends = await _friendService.isFriends(currentUID, toUID);
    if (isFriends) return "friends";

    // Check if request is pending
    final status = await _friendService.getStatus(currentUID, toUID);
    return status;
  }

  Future<void> _sendFriendRequest(String fromUID, String toUID) async {
    try {
      await _friendService.sendFriendRequest(fromUID, toUID);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Friend request sent!")),
        );
        setState(() {}); // Refresh to update button state
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Widget _buildFriendsList(String currentUID) {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.getFriends(currentUID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No friends yet\nStart typing to search users",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final friendDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: friendDocs.length,
          itemBuilder: (context, index) {
            final friendDoc = friendDocs[index];
            final data = friendDoc.data() as Map<String, dynamic>;
            final friendUID = data["friendUID"] ?? friendDoc.id;
            final friendName = data["friendName"] ?? "Unknown";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("Users")
                  .doc(friendUID)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text("Loading..."));
                }

                final friendEmail = userSnapshot.data!["email"] ?? "Unknown";

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(friendName),
                    subtitle: Text(friendEmail),
                    leading: const Icon(Icons.person, color: Colors.green),
                    onTap: () {
                      // Navigate to chat page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverEmail: friendEmail,
                            receiverID: friendUID,
                            receiverName: friendName,
                          ),
                        ),
                      );
                    },
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text("Edit Name"),
                          onTap: () {
                            _showEditNameDialog(
                                context, currentUID, friendUID, friendName);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text("Remove Friend"),
                          onTap: () {
                            _showRemoveFriendDialog(
                                context, currentUID, friendUID, friendName);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context, String currentUID,
      String friendUID, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Edit Friend Name',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter new name',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Current name: $currentName',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                Navigator.of(context).pop();
                return;
              }

              if (newName == currentName) {
                Navigator.of(context).pop();
                return;
              }

              // Check if name already exists for another friend
              final isDuplicateName = await _checkDuplicateFriendName(
                  currentUID, newName, friendUID);

              if (isDuplicateName) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('This name is already used for another friend'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }

              try {
                await _friendService.updateFriendName(
                    currentUID, friendUID, newName);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend name updated successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkDuplicateFriendName(
      String currentUID, String newName, String excludeFriendUID) async {
    final friendsSnapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUID)
        .collection("friends")
        .get();

    for (final doc in friendsSnapshot.docs) {
      final data = doc.data();
      final friendName = data["friendName"] ?? "";
      final friendUID = doc.id;

      // Check if name matches and it's not the same friend being edited
      if (friendName.toLowerCase() == newName.toLowerCase() &&
          friendUID != excludeFriendUID) {
        return true;
      }
    }
    return false;
  }

  void _showRemoveFriendDialog(BuildContext context, String currentUID,
      String friendUID, String friendName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Remove $friendName from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _friendService.removeFriend(currentUID, friendUID);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend removed')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing friend: $e')),
          );
        }
      }
    }
  }
}
