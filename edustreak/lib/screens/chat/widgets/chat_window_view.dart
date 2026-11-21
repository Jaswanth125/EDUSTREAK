import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/chat_model.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../services/realtime_chat_service.dart';
import '../../../utils/edustreak_theme.dart';
import 'chat_message_composer.dart';

class ChatWindowView extends StatefulWidget {
  final UserModel currentUser;
  final ChatModel chat;
  final VoidCallback? onBack;
  final VoidCallback? onToggleInfoPanel;
  final bool isInfoPanelOpen;
  final bool isMobile;
  final Function(List<MessageModel> messages)? onMessagesUpdated;
  final ValueNotifier<List<MessageModel>>? messagesNotifier;

  const ChatWindowView({
    super.key,
    required this.currentUser,
    required this.chat,
    this.onBack,
    this.onToggleInfoPanel,
    this.isInfoPanelOpen = false,
    this.isMobile = false,
    this.onMessagesUpdated,
    this.messagesNotifier,
  });

  @override
  State<ChatWindowView> createState() => _ChatWindowViewState();
}

class _ChatWindowViewState extends State<ChatWindowView> {
  final RealtimeChatService _chatService = RealtimeChatService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inChatSearchController = TextEditingController();

  Stream<List<MessageModel>>? _messagesStream;
  Stream<ChatModel?>? _chatStream;
  Stream<Map<String, dynamic>?>? _presenceStream;
  String? _subscribedChatId;

  bool _isSearching = false;
  MessageModel? _replyToMessage;
  int _previousMessageCount = 0;

  void _initStreams() {
    if (_subscribedChatId != widget.chat.id) {
      _subscribedChatId = widget.chat.id;
      _messagesStream = _chatService.streamMessages(widget.chat.id);
      _chatStream = _chatService.streamChat(widget.chat.id);
      final otherUserId = widget.chat.getOtherParticipantId(widget.currentUser.id);
      _presenceStream = _chatService.streamUserPresence(otherUserId);
    }
  }

  @override
  void initState() {
    super.initState();
    _initStreams();
    _markRead();
    _inChatSearchController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant ChatWindowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat.id != widget.chat.id) {
      _initStreams();
      _markRead();
      _replyToMessage = null;
      _isSearching = false;
      _previousMessageCount = 0;
      _inChatSearchController.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inChatSearchController.dispose();
    super.dispose();
  }

  bool _isMessageListEqual(List<MessageModel> a, List<MessageModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    if (a.isEmpty && b.isEmpty) return true;
    return a.first.id == b.first.id && a.last.id == b.last.id;
  }

  void _syncMessages(List<MessageModel> messages) {
    if (widget.messagesNotifier != null && !_isMessageListEqual(widget.messagesNotifier!.value, messages)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.messagesNotifier != null) {
          widget.messagesNotifier!.value = messages;
        }
      });
    }

    // Auto-scroll on new message if user is near the bottom
    if (messages.length > _previousMessageCount) {
      _previousMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 140) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
  }

  void _markRead() {
    _chatService.markChatAsRead(
      currentUserId: widget.currentUser.id,
      otherUserId: widget.chat.getOtherParticipantId(widget.currentUser.id),
      chatId: widget.chat.id,
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return EduStreakTheme.emeraldGreen;
      case 'student':
        return EduStreakTheme.neonCyan;
      case 'parent':
        return EduStreakTheme.amberGold;
      case 'principal':
        return EduStreakTheme.purpleHighlight;
      case 'admin':
        return EduStreakTheme.rosePink;
      default:
        return EduStreakTheme.primaryViolet;
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(messageDate).inDays;
    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showMessageActionsModal(BuildContext context, MessageModel message) {
    final isMe = message.senderId == widget.currentUser.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick Reaction Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCardSub,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['👍', '❤️', '👏', '🙏', '😊', '🎯'].map((emoji) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _chatService.toggleReaction(
                          chatId: widget.chat.id,
                          messageId: message.id,
                          emoji: emoji,
                          userId: widget.currentUser.id,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Reply
              ListTile(
                dense: true,
                leading: const Icon(Icons.reply_rounded, color: EduStreakTheme.neonCyan),
                title: const Text('Reply', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyToMessage = message);
                },
              ),

              // Copy Text
              if (message.text.isNotEmpty && !message.isDeleted)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.copy_rounded, color: EduStreakTheme.primaryVioletLight),
                  title: const Text('Copy Message', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

              // Edit Message
              if (isMe && !message.isDeleted)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.edit_rounded, color: EduStreakTheme.amberGold),
                  title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context, message);
                  },
                ),

              // Delete Message
              if ((isMe || widget.currentUser.isAdmin) && !message.isDeleted)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmationDialog(context, message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, MessageModel message) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: EduStreakTheme.studentDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
        ),
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this message? This action will remove its content for everyone.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _chatService.deleteMessage(
                chatId: widget.chat.id,
                messageId: message.id,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, MessageModel message) {
    final editController = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: EduStreakTheme.studentDarkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
        ),
        title: const Text(
          'Edit Message',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Edit your message...',
            hintStyle: TextStyle(color: Colors.white38),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                _chatService.editMessage(
                  chatId: widget.chat.id,
                  messageId: message.id,
                  newText: newText,
                );
              }
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _previewImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.85 * 255).round()),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _chatService.resolveParticipantNameSync(widget.chat, widget.currentUser.id);
    final otherRole = _chatService.resolveParticipantRoleSync(widget.chat, widget.currentUser.id);
    final roleColor = _getRoleColor(otherRole);

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: EduStreakTheme.studentDarkHeader,
              border: Border(
                bottom: BorderSide(
                  color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (widget.onBack != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: widget.onBack,
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                ],

                // Avatar with real reactive online status
                StreamBuilder<Map<String, dynamic>?>(
                  stream: _presenceStream,
                  builder: (context, presenceSnap) {
                    final presence = presenceSnap.data;
                    final isOnline = presence?['isOnline'] == true;

                    return Stack(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                roleColor.withAlpha((0.85 * 255).round()),
                                roleColor.withAlpha((0.45 * 255).round()),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: EduStreakTheme.emeraldGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: EduStreakTheme.studentDarkHeader,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(width: 12),

                // Name & Role & Real-Time Presence
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              otherName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: roleColor.withAlpha((0.18 * 255).round()),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: roleColor.withAlpha((0.4 * 255).round()),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              otherRole.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: _presenceStream,
                        builder: (context, presenceSnap) {
                          final presence = presenceSnap.data;
                          final isOnline = presence?['isOnline'] == true;
                          final lastSeenVal = presence?['lastSeen'];
                          DateTime? lastSeen;
                          if (lastSeenVal is DateTime) lastSeen = lastSeenVal;

                          String statusText;
                          Color statusColor;

                          if (isOnline) {
                            statusText = 'Active Now';
                            statusColor = EduStreakTheme.emeraldGreen;
                          } else if (lastSeen != null) {
                            final diff = DateTime.now().difference(lastSeen);
                            if (diff.inMinutes < 60) {
                              statusText = 'Active ${diff.inMinutes}m ago';
                            } else if (diff.inHours < 24) {
                              statusText = 'Active ${diff.inHours}h ago';
                            } else {
                              statusText = 'Offline';
                            }
                            statusColor = EduStreakTheme.studentDarkTextMuted;
                          } else {
                            statusText = 'Offline';
                            statusColor = EduStreakTheme.studentDarkTextMuted;
                          }

                          return Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: EduStreakTheme.studentDarkTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Search in Chat Toggle
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: _isSearching ? EduStreakTheme.primaryVioletLight : Colors.white70,
                    size: 20,
                  ),
                  tooltip: 'Search in conversation',
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _inChatSearchController.clear();
                    });
                  },
                ),

                // Info Panel Toggle
                if (widget.onToggleInfoPanel != null)
                  IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: widget.isInfoPanelOpen
                          ? EduStreakTheme.primaryVioletLight
                          : Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Details & Shared Media',
                    onPressed: widget.onToggleInfoPanel,
                  ),
              ],
            ),
          ),

          // Search In Chat Bar
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EduStreakTheme.studentDarkCardSub,
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: EduStreakTheme.primaryVioletLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inChatSearchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Filter messages by text...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_inChatSearchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white54),
                      onPressed: () => _inChatSearchController.clear(),
                    ),
                ],
              ),
            ),

          // Messages List Stream (Stable subscription)
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  );
                }

                final messages = snapshot.data ?? [];
                _syncMessages(messages);

                final searchQuery = _inChatSearchController.text.trim().toLowerCase();
                final displayMessages = searchQuery.isEmpty
                    ? messages
                    : messages.where((m) => m.text.toLowerCase().contains(searchQuery)).toList();

                if (displayMessages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: EduStreakTheme.studentDarkCardSub,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.waving_hand_rounded,
                              size: 36,
                              color: EduStreakTheme.amberGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'No messages matching "$searchQuery"'
                                : 'Say hello to $otherName!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Send a note, assignment query, or update.',
                            style: TextStyle(
                              color: EduStreakTheme.studentDarkTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final message = displayMessages[index];
                    final isMe = message.senderId == widget.currentUser.id;

                    // Date Separator calculation
                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevMessage = displayMessages[index - 1];
                      if (message.timestamp != null && prevMessage.timestamp != null) {
                        showDateSeparator = !_isSameDay(message.timestamp!, prevMessage.timestamp!);
                      }
                    }

                    return Column(
                      key: ValueKey('msg_${message.id}'),
                      children: [
                        if (showDateSeparator && message.timestamp != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: EduStreakTheme.studentDarkCardSub.withAlpha((0.7 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: EduStreakTheme.studentDarkBorder.withAlpha((0.4 * 255).round()),
                                  ),
                                ),
                                child: Text(
                                  _formatDateSeparator(message.timestamp!),
                                  style: TextStyle(
                                    color: EduStreakTheme.studentDarkTextMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        _buildMessageBubble(context, message, isMe),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Live Typing Indicator (Stable Stream)
          StreamBuilder<ChatModel?>(
            stream: _chatStream,
            builder: (context, chatSnap) {
              final activeChat = chatSnap.data ?? widget.chat;
              final otherId = widget.chat.getOtherParticipantId(widget.currentUser.id);
              final isOtherTyping = activeChat.isUserTyping(otherId);

              if (!isOtherTyping) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: EduStreakTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$otherName is typing...',
                      style: const TextStyle(
                        color: EduStreakTheme.neonCyan,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Composer
          ChatMessageComposer(
            chatId: widget.chat.id,
            replyToMessage: _replyToMessage,
            onCancelReply: () => setState(() => _replyToMessage = null),
            onTypingStatusChanged: (isTyping) {
              _chatService.setTypingStatus(
                chatId: widget.chat.id,
                userId: widget.currentUser.id,
                isTyping: isTyping,
              );
            },
            onSendMessage: ({
              required String text,
              String type = 'text',
              String? attachmentUrl,
              String? attachmentName,
              int? attachmentSize,
            }) {
              _chatService.sendMessage(
                senderId: widget.currentUser.id,
                senderRole: widget.currentUser.role,
                senderName: widget.currentUser.name,
                receiverId: widget.chat.getOtherParticipantId(widget.currentUser.id),
                receiverRole: otherRole,
                receiverName: otherName,
                text: text,
                type: type,
                attachmentUrl: attachmentUrl,
                attachmentName: attachmentName,
                attachmentSize: attachmentSize,
                replyToId: _replyToMessage?.id,
                replyToText: _replyToMessage?.text,
                replyToSender: _replyToMessage?.senderName,
                schoolId: widget.currentUser.schoolId,
              );

              setState(() => _replyToMessage = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, MessageModel message, bool isMe) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.isMobile ? MediaQuery.of(context).size.width * 0.82 : 460,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => _showMessageActionsModal(context, message),
              onSecondaryTap: () => _showMessageActionsModal(context, message),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? EduStreakTheme.activePillGradient : null,
                  color: isMe ? null : EduStreakTheme.studentDarkCard,
                  borderRadius: bubbleRadius,
                  border: isMe
                      ? null
                      : Border.all(
                          color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.2 * 255).round()),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply Quote inside bubble
                    if (message.replyToText != null && message.replyToText!.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.25 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white70 : EduStreakTheme.primaryVioletLight,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyToSender ?? 'Replying',
                              style: TextStyle(
                                color: isMe ? Colors.white : EduStreakTheme.primaryVioletLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replyToText!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Attachment render
                    if (message.type == 'image' && message.attachmentUrl != null && !message.isDeleted) ...[
                      GestureDetector(
                        onTap: () => _previewImage(context, message.attachmentUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            message.attachmentUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.white54),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ] else if (message.type == 'file' && !message.isDeleted) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) {
                              final uri = Uri.tryParse(message.attachmentUrl!);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_rounded,
                                  color: EduStreakTheme.neonCyan,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.attachmentName ?? 'Document',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${((message.attachmentSize ?? 0) / 1024).round()} KB • Tap to view',
                                        style: TextStyle(
                                          color: EduStreakTheme.studentDarkTextMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Text Content with Telugu/English unicode support
                    if (message.isDeleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.block_rounded, size: 14, color: Colors.white54),
                          SizedBox(width: 6),
                          Text(
                            'This message was deleted',
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Timestamp, Edited, Read Receipt
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.isEdited && !message.isDeleted) ...[
                          Text(
                            'edited ',
                            style: TextStyle(
                              color: Colors.white.withAlpha((0.55 * 255).round()),
                              fontSize: 9.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.65 * 255).round()),
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.read
                                ? Icons.done_all_rounded
                                : (message.deliveryStatus == 'delivered'
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded),
                            size: 13,
                            color: message.read ? EduStreakTheme.neonCyan : Colors.white60,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Emoji Reactions Row
            if (message.reactions.isNotEmpty) ...[
              const SizedBox(height: 3),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: message.reactions.entries.map((entry) {
                  final emoji = entry.key;
                  final uids = entry.value;
                  final hasReacted = uids.contains(widget.currentUser.id);

                  return InkWell(
                    onTap: () => _chatService.toggleReaction(
                      chatId: widget.chat.id,
                      messageId: message.id,
                      emoji: emoji,
                      userId: widget.currentUser.id,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasReacted
                            ? EduStreakTheme.primaryViolet.withAlpha((0.35 * 255).round())
                            : EduStreakTheme.studentDarkCardSub,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasReacted
                              ? EduStreakTheme.primaryVioletLight
                              : EduStreakTheme.studentDarkBorder.withAlpha((0.5 * 255).round()),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 12)),
                          if (uids.length > 1) ...[
                            const SizedBox(width: 3),
                            Text(
                              uids.length.toString(),
                              style: TextStyle(
                                color: hasReacted ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
