import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import 'chat_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _availableUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final List<Map<String, dynamic>> users = [];

    try {
      if (currentUser.role == 'teacher') {
        // Teachers can message: Students in their classes, Parents of those students, Other teachers
        final classIds = currentUser.classIds ?? [];
        
        if (classIds.isNotEmpty) {
          // Get students in teacher's classes (in chunks of 10 due to Firestore limit)
          for (var i = 0; i < classIds.length; i += 10) {
            final chunk = classIds.sublist(
              i,
              i + 10 > classIds.length ? classIds.length : i + 10,
            );
            final studentsSnapshot = await _firestore
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('classId', whereIn: chunk)
                .get();
            
            for (final doc in studentsSnapshot.docs) {
              final data = doc.data();
              if (doc.id != currentUser.id) {
                users.add({
                  'id': doc.id,
                  'name': data['name'] ?? 'Student',
                  'role': 'student',
                });
              }
            }
          }

          // Get parents of those students
          final studentIds = users
              .where((u) => u['role'] == 'student')
              .map((u) => u['id'] as String)
              .toList();
          
          if (studentIds.isNotEmpty) {
            for (var i = 0; i < studentIds.length; i += 10) {
              final chunk = studentIds.sublist(
                i,
                i + 10 > studentIds.length ? studentIds.length : i + 10,
              );
              final parentsSnapshot = await _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'parent')
                  .where('childId', whereIn: chunk)
                  .get();
              
              for (final doc in parentsSnapshot.docs) {
                final data = doc.data();
                if (doc.id != currentUser.id) {
                  users.add({
                    'id': doc.id,
                    'name': data['name'] ?? 'Parent',
                    'role': 'parent',
                  });
                }
              }
            }
          }
        }

        // Get other teachers
        final teachersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get();
        
        for (final doc in teachersSnapshot.docs) {
          if (doc.id != currentUser.id) {
            final data = doc.data();
            users.add({
              'id': doc.id,
              'name': data['name'] ?? 'Teacher',
              'role': 'teacher',
            });
          }
        }
      } else if (currentUser.role == 'student') {
        // Students can message: Their teacher(s), Classmates
        if (currentUser.classId != null) {
          // Get teachers of their class
          final teachersSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .where('classIds', arrayContains: currentUser.classId)
              .get();
          
          for (final doc in teachersSnapshot.docs) {
            final data = doc.data();
            users.add({
              'id': doc.id,
              'name': data['name'] ?? 'Teacher',
              'role': 'teacher',
            });
          }

          // Get classmates
          final classmatesSnapshot = await _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('classId', isEqualTo: currentUser.classId)
              .get();
          
          for (final doc in classmatesSnapshot.docs) {
            if (doc.id != currentUser.id) {
              final data = doc.data();
              users.add({
                'id': doc.id,
                'name': data['name'] ?? 'Classmate',
                'role': 'student',
              });
            }
          }
        }
      } else if (currentUser.role == 'parent') {
        // Parents can message: Their child's teacher(s)
        if (currentUser.childId != null) {
          final childDoc = await _firestore
              .collection('users')
              .doc(currentUser.childId)
              .get();
          
          if (childDoc.exists) {
            final childData = childDoc.data()!;
            final childClassId = childData['classId'];
            
            if (childClassId != null) {
              final teachersSnapshot = await _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'teacher')
                  .where('classIds', arrayContains: childClassId)
                  .get();
              
              for (final doc in teachersSnapshot.docs) {
                final data = doc.data();
                users.add({
                  'id': doc.id,
                  'name': data['name'] ?? 'Teacher',
                  'role': 'teacher',
                });
              }
            }
          }
        }
      }

      // Remove duplicates and sort
      final uniqueUsers = <String, Map<String, dynamic>>{};
      for (final user in users) {
        uniqueUsers[user['id'] as String] = user;
      }
      
      final sortedUsers = uniqueUsers.values.toList()
        ..sort((a, b) => (a['name'] as String)
            .toLowerCase()
            .compareTo((b['name'] as String).toLowerCase()));

      setState(() {
        _availableUsers = sortedUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _availableUsers;
    final query = _searchQuery.toLowerCase();
    return _availableUsers
        .where((user) =>
            (user['name'] as String).toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No users available to message'
                              : 'No users found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final name = user['name'] as String;
                          final role = user['role'] as String;
                          final userId = user['id'] as String;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(role),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: userId,
                                    otherUserName: name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'teacher':
        return Colors.blue;
      case 'parent':
        return Colors.green;
      case 'student':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

