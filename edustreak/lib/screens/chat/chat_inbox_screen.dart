import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';
import 'user_list_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  final bool showAppBar;

  const ChatInboxScreen({super.key, this.showAppBar = true});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final Map<String, Map<String, dynamic>> _userCache = {};

  Future<Map<String, dynamic>?> _fetchUser(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid];
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!..['id'] = doc.id;
        _userCache[uid] = data;
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching user $uid: $e');
    }
    return null;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Color _getRoleColor(String? role) {
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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final chatService = ChatService();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Messages'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'New Chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserListScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      floatingActionButton: !widget.showAppBar
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserListScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatService.streamInbox(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            final isIndexError = errorMsg.contains('index') || 
                                 errorMsg.contains('requires an index');
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading messages',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isIndexError)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Firestore Index Required',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please create a composite index in Firebase Console:\n'
                              'Collection: messages\n'
                              'Fields: participants (Array), lastTimestamp (Descending)',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        errorMsg,
                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          var threads = snapshot.data?.docs ?? [];
          
          // Sort by lastTimestamp if not already sorted (fallback for missing index)
          threads.sort((a, b) {
            final aTime = a.data()['lastTimestamp'] as Timestamp?;
            final bTime = b.data()['lastTimestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });
          
          if (threads.isEmpty) {
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
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to start a new chat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final data = threads[index].data();
              final participants =
                  List<String>.from(data['participants'] ?? const []);
              final otherUid =
                  participants.firstWhere((id) => id != currentUser.id);
              final unreadMap = data['unreadCount'] as Map<String, dynamic>? ??
                  <String, dynamic>{};
              final unread = (unreadMap[currentUser.id] ?? 0) as int;
              final lastMessage = data['lastMessage'] ?? '';
              final lastTimestamp = data['lastTimestamp'] as Timestamp?;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUser(otherUid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircularProgressIndicator(strokeWidth: 2),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data;
                  final otherName = userData?['name'] ?? 'Unknown User';
                  final otherRole = userData?['role'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(otherRole),
                      child: Text(
                        otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: TextStyle(
                              fontWeight: unread > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (otherRole.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(otherRole).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              otherRole.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(otherRole),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: unread > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: unread > 0 ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(lastTimestamp),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: otherUid,
                            otherUserName: otherName,
                          ),
                        ),
                      ).then((_) {
                        // Refresh user cache when returning
                        _userCache.remove(otherUid);
                      });
                    },
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

