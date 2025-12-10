import 'package:flutter/material.dart';
import 'package:smart_daily_planner/pages/friend_requests_page.dart';
import '../services/auth/auth_service.dart';
import '../services/friend_service.dart';
import '../pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout() {
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final userEmail = auth.getCurrentUser()?.email ?? 'Tidak ada email';

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          // HOME
          ListTile(
            leading:
                Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
            title: Text('H O M E',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18)),
            onTap: () => Navigator.pop(context),
          ),

          // FRIEND REQUESTS (with badge)
          Builder(builder: (ctx) {
            final auth = AuthService();
            final currentUID = auth.getCurrentUser()?.uid;
            final friendService = FriendService();

            if (currentUID == null) {
              return ListTile(
                leading: Icon(Icons.people,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(
                  'F R I E N D \nR E Q U E S T S',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FriendRequestsPage()),
                  );
                },
              );
            }

            return StreamBuilder(
              stream: friendService.getIncomingRequests(currentUID),
              builder: (context, snap) {
                int count = 0;
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  count = snap.data!.docs.length;
                }

                return ListTile(
                  leading: Icon(Icons.people,
                      color: Theme.of(context).colorScheme.primary),
                  title: Row(
                    children: [
                      Text(
                        'F R I E N D \nR E Q U E S T S',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FriendRequestsPage()),
                    );
                  },
                );
              },
            );
          }),

          // SETTINGS
          ListTile(
            leading: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.primary),
            title: Text('S E T T I N G S',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),

          // LOGOUT
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.primary),
            title: Text('L O G O U T',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18)),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}
