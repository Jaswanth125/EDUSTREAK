import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import '../../../services/realtime_chat_service.dart';
import '../../../utils/edustreak_theme.dart';

class ConversationSidebar extends StatefulWidget {
  final UserModel currentUser;
  final String? selectedChatId;
  final ValueChanged<ChatModel> onSelectChat;
  final VoidCallback onNewChat;
  final bool isMobile;

  const ConversationSidebar({
    super.key,
    required this.currentUser,
    required this.selectedChatId,
    required this.onSelectChat,
    required this.onNewChat,
    this.isMobile = false,
  });

  @override
  State<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends State<ConversationSidebar> {
  final RealtimeChatService _chatService = RealtimeChatService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, unread, teacher, student, parent

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
    }
  }

  void _showChatOptionsMenu(BuildContext context, ChatModel chat) {
    final otherName = chat.getOtherParticipantName(widget.currentUser.id);
    final isPinned = chat.isPinned;
    final isMuted = chat.isMutedFor(widget.currentUser.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                otherName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: EduStreakTheme.primaryVioletLight,
                ),
                title: Text(
                  isPinned ? 'Unpin Conversation' : 'Pin Conversation to Top',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _chatService.togglePinChat(
                    chatId: chat.id,
                    currentIsPinned: isPinned,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: isMuted ? EduStreakTheme.emeraldGreen : Colors.orangeAccent,
                ),
                title: Text(
                  isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _chatService.toggleMuteChat(
                    chatId: chat.id,
                    userId: widget.currentUser.id,
                    currentMuted: isMuted,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.mark_chat_read_rounded,
                  color: EduStreakTheme.neonCyan,
                ),
                title: const Text(
                  'Mark as Read',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _chatService.markChatAsRead(
                    currentUserId: widget.currentUser.id,
                    otherUserId: chat.getOtherParticipantId(widget.currentUser.id),
                    chatId: chat.id,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkSidebar,
        border: widget.isMobile
            ? null
            : Border(
                right: BorderSide(
                  color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
                  width: 1,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header & New Chat Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: EduStreakTheme.activePillGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: EduStreakTheme.primaryViolet.withAlpha((0.35 * 255).round()),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                // New Message Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onNewChat,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: EduStreakTheme.activePillGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: EduStreakTheme.primaryViolet.withAlpha((0.3 * 255).round()),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_note_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: EduStreakTheme.studentDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EduStreakTheme.studentDarkBorder.withAlpha((0.4 * 255).round()),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.6 * 255).round()),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: EduStreakTheme.primaryVioletLight,
                    size: 18,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white54),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Filter Chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 6),
                _buildFilterChip('unread', 'Unread'),
                const SizedBox(width: 6),
                _buildFilterChip('teacher', 'Teachers'),
                const SizedBox(width: 6),
                _buildFilterChip('student', 'Students'),
                const SizedBox(width: 6),
                _buildFilterChip('parent', 'Parents'),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),

          // Realtime Conversation List Stream
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getUserChatsStream(widget.currentUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red[300], size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[300], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final rawChats = snapshot.data ?? [];
                final query = _searchController.text.trim().toLowerCase();

                final filteredChats = rawChats.where((chat) {
                  final otherName = chat.getOtherParticipantName(widget.currentUser.id).toLowerCase();
                  final otherRole = chat.getOtherParticipantRole(widget.currentUser.id).toLowerCase();
                  final lastMsg = chat.lastMessage.toLowerCase();

                  // Filter chip logic
                  if (_selectedFilter == 'unread') {
                    if (chat.getUnreadCount(widget.currentUser.id) <= 0) return false;
                  } else if (_selectedFilter != 'all') {
                    if (otherRole != _selectedFilter) return false;
                  }

                  // Search query logic
                  if (query.isNotEmpty) {
                    if (!otherName.contains(query) && !lastMsg.contains(query)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.35 * 255).round()),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rawChats.isEmpty
                                ? 'No chats started yet'
                                : 'No matching conversations',
                            style: const TextStyle(
                              color: EduStreakTheme.studentDarkTextMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rawChats.isEmpty
                                ? 'Tap "New" to message a teacher, student, or parent.'
                                : 'Try searching with another name or filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.6 * 255).round()),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: filteredChats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    final isSelected = widget.selectedChatId == chat.id;
                    final otherName = chat.getOtherParticipantName(widget.currentUser.id);
                    final otherRole = chat.getOtherParticipantRole(widget.currentUser.id);
                    final unreadCount = chat.getUnreadCount(widget.currentUser.id);
                    final roleColor = _getRoleColor(otherRole);
                    final isMuted = chat.isMutedFor(widget.currentUser.id);

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => widget.onSelectChat(chat),
                        onLongPress: () => _showChatOptionsMenu(context, chat),
                        borderRadius: BorderRadius.circular(14),
                        hoverColor: EduStreakTheme.primaryViolet.withAlpha((0.15 * 255).round()),
                        splashColor: EduStreakTheme.primaryViolet.withAlpha((0.25 * 255).round()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? EduStreakTheme.primaryViolet.withAlpha((0.22 * 255).round())
                                : unreadCount > 0
                                    ? EduStreakTheme.studentDarkCardSub.withAlpha((0.45 * 255).round())
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? EduStreakTheme.primaryViolet
                                  : unreadCount > 0
                                      ? EduStreakTheme.studentDarkBorder.withAlpha((0.7 * 255).round())
                                      : Colors.transparent,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar with Role Indicator Ring
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          roleColor.withAlpha((0.85 * 255).round()),
                                          roleColor.withAlpha((0.4 * 255).round()),
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
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Online Status dot
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: EduStreakTheme.emeraldGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: EduStreakTheme.studentDarkSidebar,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 12),

                              // Name, Role & Last Message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Pinned Indicator
                                        if (chat.isPinned) ...[
                                          const Icon(
                                            Icons.push_pin_rounded,
                                            size: 13,
                                            color: EduStreakTheme.primaryVioletLight,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        // Name
                                        Expanded(
                                          child: Text(
                                            otherName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Timestamp
                                        Text(
                                          _formatTime(chat.lastUpdated),
                                          style: TextStyle(
                                            color: unreadCount > 0
                                                ? EduStreakTheme.primaryVioletLight
                                                : EduStreakTheme.studentDarkTextMuted,
                                            fontSize: 11,
                                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 3),

                                    Row(
                                      children: [
                                        // Role Mini Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: roleColor.withAlpha((0.15 * 255).round()),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            otherRole.toUpperCase(),
                                            style: TextStyle(
                                              color: roleColor,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Last Message Preview
                                        Expanded(
                                          child: Text(
                                            chat.lastMessage.isEmpty ? 'Started conversation' : chat.lastMessage,
                                            style: TextStyle(
                                              color: unreadCount > 0
                                                  ? Colors.white
                                                  : EduStreakTheme.studentDarkTextMuted,
                                              fontSize: 12,
                                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Muted Indicator
                                        if (isMuted) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.volume_off_rounded,
                                            size: 13,
                                            color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.5 * 255).round()),
                                          ),
                                        ],

                                        // Unread Badge
                                        if (unreadCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              gradient: EduStreakTheme.activePillGradient,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: EduStreakTheme.primaryViolet.withAlpha((0.5 * 255).round()),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? EduStreakTheme.primaryViolet.withAlpha((0.25 * 255).round())
              : EduStreakTheme.studentDarkCard.withAlpha((0.5 * 255).round()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? EduStreakTheme.primaryViolet
                : EduStreakTheme.studentDarkBorder.withAlpha((0.4 * 255).round()),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
