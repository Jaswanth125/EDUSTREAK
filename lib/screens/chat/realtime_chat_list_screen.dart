import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/realtime_chat_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';
import 'realtime_chat_screen.dart';

/// Real-time chat list screen for all roles
/// Shows all chats with real-time updates using Firestore streams
class RealtimeChatListScreen extends StatefulWidget {
  const RealtimeChatListScreen({super.key});

  @override
  State<RealtimeChatListScreen> createState() => _RealtimeChatListScreenState();
}

class _RealtimeChatListScreenState extends State<RealtimeChatListScreen> {
  final RealtimeChatService _chatService = RealtimeChatService();
  StreamSubscription? _chatsSubscription;

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: AppLogo(size: 30),
        ),
        leadingWidth: 66,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          // Add button for starting new chats (role-based)
          if (currentUser.role == 'teacher' || currentUser.role == 'parent' || currentUser.role == 'student')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showNewChatDialog(context, currentUser),
            ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.getUserChatsStream(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Stream automatically updates, just trigger rebuild
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatListItem(context, chat, currentUser);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, ChatModel chat, UserModel currentUser) {
    final otherUserId = chat.getOtherParticipantId(currentUser.id);
    final unreadCount = chat.getUnreadCount(currentUser.id);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(otherUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final otherUser = userSnapshot.data!;
        final otherUserName = otherUser['name'] ?? 'Unknown';
        final otherUserRole = otherUser['role'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RealtimeChatScreen(
                      chatId: chat.id,
                      otherUserId: otherUserId,
                      otherUserName: otherUserName,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          otherUserName.isNotEmpty 
                              ? otherUserName[0].toUpperCase() 
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Chat info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherUserName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (chat.lastTimestamp != null)
                                Text(
                                  _formatTime(chat.lastTimestamp!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Role badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(otherUserRole).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  otherUserRole.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getRoleColor(otherUserRole),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Last message
                              Expanded(
                                child: Text(
                                  chat.lastMessage.isEmpty
                                      ? 'No messages yet'
                                      : chat.lastMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: chat.lastMessage.isEmpty
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unread badge
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student':
        return AppTheme.primaryColor;
      case 'parent':
        return AppTheme.accentColor;
      case 'teacher':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _showNewChatDialog(BuildContext context, UserModel currentUser) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final Map<String, Map<String, dynamic>> contactMap = {};

      void addContact(QueryDocumentSnapshot doc,
          {String fallbackName = 'User', String fallbackRole = 'user'}) {
        if (doc.id == currentUser.id) return;
        final data = doc.data() as Map<String, dynamic>;
        final rawName = (data['name'] as String?)?.trim() ?? '';
        final role = (data['role'] as String?) ?? fallbackRole;
        contactMap[doc.id] = {
          'id': doc.id,
          'name': rawName.isEmpty ? fallbackName : rawName,
          'role': role,
          'email': data['email'] ?? '',
        };
      }

      List<List<String>> chunk(List<String> source, int size) {
        if (source.isEmpty) return [];
        if (source.length <= size) return [List<String>.from(source)];
        final chunks = <List<String>>[];
        for (var i = 0; i < source.length; i += size) {
          chunks.add(source.sublist(i, math.min(i + size, source.length)));
        }
        return chunks;
      }

      Future<void> addAdmins() async {
        final adminsSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        for (final doc in adminsSnapshot.docs) {
          addContact(doc, fallbackName: 'Admin', fallbackRole: 'admin');
        }
      }

      if (currentUser.role == 'student') {
        if (currentUser.classId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are not assigned to any class. Please contact admin.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final teachersSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .where('classIds', arrayContains: currentUser.classId)
            .get();
        for (final doc in teachersSnapshot.docs) {
          addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
        }

        final classmatesSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('classId', isEqualTo: currentUser.classId)
            .get();
        for (final doc in classmatesSnapshot.docs) {
          addContact(doc, fallbackName: 'Classmate', fallbackRole: 'student');
        }

        await addAdmins();
      } else if (currentUser.role == 'teacher') {
        final classIds = currentUser.classIds ?? [];
        final List<String> studentIds = [];

        if (classIds.isNotEmpty) {
          for (final classChunk in chunk(classIds, 10)) {
            final studentsSnapshot = await firestore
                .collection('users')
                .where('role', isEqualTo: 'student')
                .where('classId', whereIn: classChunk)
                .get();
            for (final doc in studentsSnapshot.docs) {
              addContact(doc, fallbackName: 'Student', fallbackRole: 'student');
              studentIds.add(doc.id);
            }
          }

          for (final studentChunk in chunk(studentIds, 10)) {
            final parentsSnapshot = await firestore
                .collection('users')
                .where('role', isEqualTo: 'parent')
                .where('childId', whereIn: studentChunk)
                .get();
            for (final doc in parentsSnapshot.docs) {
              addContact(doc, fallbackName: 'Parent', fallbackRole: 'parent');
            }
          }
        }

        final otherTeachersSnapshot = await firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .get();
        for (final doc in otherTeachersSnapshot.docs) {
          addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
        }

        await addAdmins();
      } else if (currentUser.role == 'parent') {
        if (currentUser.childId == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No child linked to your account.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final childDoc = await firestore
            .collection('users')
            .doc(currentUser.childId)
            .get();

        if (!childDoc.exists) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Child account not found.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final childData = childDoc.data()!;
        final childClassId = childData['classId'];
        if (childClassId != null) {
          final teachersSnapshot = await firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .where('classIds', arrayContains: childClassId)
              .get();
          for (final doc in teachersSnapshot.docs) {
            addContact(doc, fallbackName: 'Teacher', fallbackRole: 'teacher');
          }
        }

        await addAdmins();
      } else if (currentUser.role == 'admin') {
        final usersSnapshot = await firestore.collection('users').get();
        for (final doc in usersSnapshot.docs) {
          addContact(doc);
        }
      } else {
        final usersSnapshot = await firestore.collection('users').get();
        for (final doc in usersSnapshot.docs) {
          addContact(doc);
        }
      }

      final availableUsers = contactMap.values.toList()
        ..sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));

      if (availableUsers.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No users available to chat with.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Start New Chat'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: double.infinity,
                maxHeight: 400,
              ),
              child: availableUsers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No users available to chat with.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = availableUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              (user['name'] as String).isNotEmpty
                                  ? (user['name'] as String)[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user['name'] as String),
                          subtitle: Text('${user['role'] as String} • ${user['email'] as String}'),
                          onTap: () async {
                            Navigator.pop(context);
                            await _startChatWithUser(
                              context,
                              currentUser,
                              user['id'] as String,
                              user['name'] as String,
                              user['role'] as String,
                            );
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChatWithUser(
    BuildContext context,
    UserModel currentUser,
    String otherUserId,
    String otherUserName,
    String otherUserRole,
  ) async {
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final chatService = RealtimeChatService();
      
      // Get or create chat
      final chat = await chatService.getOrCreateChat(
        currentUserId: currentUser.id,
        currentUserRole: currentUser.role,
        otherUserId: otherUserId,
        otherUserRole: otherUserRole,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RealtimeChatScreen(
              chatId: chat.id,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}


