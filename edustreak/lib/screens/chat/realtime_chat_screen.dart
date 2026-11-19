import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../providers/user_provider.dart';
import '../../services/realtime_chat_service.dart';
import '../../utils/edustreak_theme.dart';
import 'widgets/chat_info_panel.dart';
import 'widgets/chat_window_view.dart';

class RealtimeChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final ChatModel? chat;

  const RealtimeChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.chat,
  });

  @override
  State<RealtimeChatScreen> createState() => _RealtimeChatScreenState();
}

class _RealtimeChatScreenState extends State<RealtimeChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RealtimeChatService _chatService = RealtimeChatService();
  List<MessageModel> _currentMessages = [];

  ChatModel _resolveChat(String currentUserId, String currentUserRole, String currentUserName) {
    if (widget.chat != null) return widget.chat!;

    return ChatModel(
      id: widget.chatId,
      participants: [currentUserId, widget.otherUserId]..sort(),
      type: _chatService.chatType(currentUserRole, widget.otherUserRole),
      lastMessage: '',
      lastUpdated: DateTime.now(),
      participantRoles: {
        currentUserId: currentUserRole,
        widget.otherUserId: widget.otherUserRole,
      },
      participantNames: {
        currentUserId: currentUserName,
        widget.otherUserId: widget.otherUserName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: EduStreakTheme.studentDarkBg,
        body: Center(
          child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
        ),
      );
    }

    final chat = _resolveChat(currentUser.id, currentUser.role, currentUser.name);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: EduStreakTheme.studentDarkBg,
      endDrawer: Drawer(
        backgroundColor: EduStreakTheme.studentDarkSidebar,
        child: SafeArea(
          child: ChatInfoPanel(
            currentUser: currentUser,
            chat: chat,
            messages: _currentMessages,
            onClose: () => Navigator.of(context).pop(),
            onToggleMute: () {
              final isMuted = chat.isMutedFor(currentUser.id);
              _chatService.toggleMuteChat(
                chatId: chat.id,
                userId: currentUser.id,
                currentMuted: isMuted,
              );
            },
            onTogglePin: () {
              _chatService.togglePinChat(
                chatId: chat.id,
                currentIsPinned: chat.isPinned,
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: ChatWindowView(
          currentUser: currentUser,
          chat: chat,
          isMobile: true,
          isInfoPanelOpen: false,
          onBack: () => Navigator.of(context).pop(),
          onToggleInfoPanel: () {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          onMessagesUpdated: (msgs) {
            if (mounted) {
              setState(() => _currentMessages = msgs);
            }
          },
        ),
      ),
    );
  }
}
