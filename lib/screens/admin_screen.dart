import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Local constants instead of external dependency
const Color kPrimaryColor = Color(0xFF4CAF50);
const Color kAccentColor = Color(0xFF8BC34A);

// Diet options constant
const List<String> dietOptions = [
  'None',
  'Vegetarian',
  'Vegan',
  'Ketogenic',
  'Paleo',
  'Mediterranean',
  'Low Carb',
  'High Protein',
  'Gluten Free'
];

// App text styles
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Initialize Cloud Functions
    _initializeCloudFunctions();
  }

  void _initializeCloudFunctions() {
    try {
      // For production, comment out the emulator line
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      print('Cloud Functions initialized');
    } catch (e) {
      print('Cloud Functions initialization error: $e');
    }
  }

  // ✅ Add logout method
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate back to auth screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        // ✅ Removes back button
        actions: [
          // ✅ Add logout button
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Warning box about email deletion
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Note: Deleted users may still exist in Firebase Auth. Use Firebase Console to fully remove auth accounts.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildUserManagementSection(),
            const SizedBox(height: 24),
            _buildContentManagementSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Statistics', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userCount = snapshot.data!.docs.length;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard('Total Users', userCount.toString(), Icons.people),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: kPrimaryColor),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(title, style: AppTextStyles.body),
      ],
    );
  }

  Widget _buildUserManagementSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Management', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').limit(5).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data!.docs[index];
                    final userData = user.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryColor,
                        child: Text(
                          (userData['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(userData['name'] ?? 'Unknown User'),
                      subtitle: Text(userData['email'] ?? 'No email'),
                      trailing: PopupMenuButton(
                        onSelected: (value) =>
                            _handleUserAction(value, user.id),
                        itemBuilder: (context) =>
                        [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                          const PopupMenuItem(
                              value: 'block', child: Text('Block')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentManagementSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Content Management', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _manageRecipes,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Recipe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPingFunction,
                    icon: const Icon(Icons.network_ping),
                    label: const Text('Test Ping'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testAuthHttpFunction,
                    icon: const Icon(Icons.security),
                    label: const Text('Test HTTP Auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewReports,
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _manageSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('App Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Test function for debugging
  Future<void> _testAuthFunction() async {
    try {
      print('Testing auth function V2...');

      // Force refresh the ID token before calling the function
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.getIdToken(true); // Force refresh
        print('ID Token refreshed for user: ${currentUser.email}');
      }

      // Use production Cloud Functions with region
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('testAuthV2');
      final result = await callable.call();
      print('Test result: ${result.data}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Auth test V2 passed: ${result.data['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Test error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test V2 failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleUserAction(String action, String userId) {
    switch (action) {
      case 'edit':
        _editUser(userId);
        break;
      case 'delete':
        _deleteUser(userId);
        break;
      case 'block':
        _blockUser(userId);
        break;
    }
  }

  void _editUser(String userId) {
    // Implementation for editing user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit user feature coming soon')),
    );
  }

  // Updated delete user method
  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Completely'),
        content: const Text(
            'This will permanently delete the user from both Authentication and Database. '
                'The email can then be re-registered. This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await _deleteUserCompletelyHttp(userId); // Use HTTP version
            },
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserCompletely(String userId) async {
    try {
      // Debug: Check authentication state in detail
      final currentUser = FirebaseAuth.instance.currentUser;
      print('=== AUTHENTICATION DEBUG ===');
      print('Current user: ${currentUser?.email}');
      print('User UID: ${currentUser?.uid}');
      print('Is user signed in: ${currentUser != null}');

      if (currentUser != null) {
        try {
          final idToken = await currentUser.getIdToken(true); // Force refresh
          print('ID Token length: ${idToken!.length}');
          if (idToken.length > 20) {
            print('ID Token starts with: ${idToken.substring(0, 20)}...');
          } else {
            print('ID Token: $idToken');
          }
        } catch (tokenError) {
          print('Error getting ID token: $tokenError');
        }
      }
      print('==============================');

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting user completely...'),
            ],
          ),
        ),
      );

      // Try refreshing the user token before calling the function
      await currentUser?.getIdToken(true);

      // Use the NEW function name deleteUserV2
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('deleteUserV2');

      print('Calling deleteUserV2 function for UID: $userId');

      final result = await callable.call({
        'uid': userId,
      });

      print('Function result: ${result.data}');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.data['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Cloud Function error: $e');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Test ping function (no auth required)
  Future<void> _testPingFunction() async {
    try {
      print('Testing ping function (no auth)...');

      // Ensure we're using production Cloud Functions with region
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('pingTest');
      final result = await callable.call({'test': 'data'});
      print('Ping result: ${result.data}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Ping test: ${result.data['message']} | Auth: ${result
                    .data['authExists']}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Ping error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ping failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _blockUser(String userId) {
    _firestore.collection('users').doc(userId).update({'blocked': true});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked successfully')),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Add New User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      emailController.text.isNotEmpty) {
                    _firestore.collection('users').add({
                      'name': nameController.text,
                      'email': emailController.text,
                      'createdAt': FieldValue.serverTimestamp(),
                      'blocked': false,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User added successfully')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _manageRecipes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe management feature coming soon')),
    );
  }

  void _manageFoodDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Food database management feature coming soon')),
    );
  }

  void _viewReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports feature coming soon')),
    );
  }

  void _manageSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings management feature coming soon')),
    );
  }

  Future<void> _testAuthHttpFunction() async {
    try {
      print('Testing HTTP auth function...');

      // Get the current user's ID token
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final idToken = await currentUser.getIdToken(true);
      print('Got ID token for HTTP request');

      // Make HTTP request to the function
      final response = await http.post(
        Uri.parse(
            'https://us-central1-meal-planner-61809.cloudfunctions.net/testAuthHttp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: '{}',
      );

      print('HTTP Response status: ${response.statusCode}');
      print('HTTP Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ HTTP Auth test passed: ${result['message']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('HTTP Auth test error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ HTTP Auth test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

// HTTP version of delete user function
  Future<void> _deleteUserCompletelyHttp(String userId) async {
    try {
      print('=== HTTP DELETE USER DEBUG ===');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print('Current user: ${currentUser.email}');

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting user completely...'),
            ],
          ),
        ),
      );

      final idToken = await currentUser.getIdToken(true);
      print('Got ID token for delete request');

      // Make HTTP request to delete user
      final response = await http.post(
        Uri.parse(
            'https://us-central1-meal-planner-61809.cloudfunctions.net/deleteUserHttp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'uid': userId}),
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('HTTP Delete error: $e');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Delete failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}