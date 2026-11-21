import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/realtime_chat_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/app_logo.dart';
import 'realtime_chat_screen.dart';
import 'widgets/chat_info_panel.dart';
import 'widgets/chat_window_view.dart';
import 'widgets/conversation_sidebar.dart';
import 'widgets/new_chat_dialog.dart';

class RealtimeChatListScreen extends StatefulWidget {
  final bool showAppBar;

  const RealtimeChatListScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<RealtimeChatListScreen> createState() => _RealtimeChatListScreenState();
}

class _RealtimeChatListScreenState extends State<RealtimeChatListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RealtimeChatService _chatService = RealtimeChatService();

  ChatModel? _selectedChat;
  bool _showInfoPanel = true;
  final ValueNotifier<List<MessageModel>> _messagesNotifier = ValueNotifier<List<MessageModel>>([]);
  UserModel? _presenceUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (user != null) {
          _presenceUser = user;
          _chatService.updatePresence(userId: user.id, isOnline: true);
        }
      }
    });
  }

  @override
  void dispose() {
    if (_presenceUser != null) {
      _chatService.updatePresence(userId: _presenceUser!.id, isOnline: false);
    }
    _messagesNotifier.dispose();
    super.dispose();
  }

  void _onSelectChat(BuildContext context, ChatModel chat, bool isMobile, UserModel currentUser) {
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RealtimeChatScreen(
            chat: chat,
            chatId: chat.id,
            otherUserId: chat.getOtherParticipantId(currentUser.id),
            otherUserName: _chatService.resolveParticipantNameSync(chat, currentUser.id),
            otherUserRole: _chatService.resolveParticipantRoleSync(chat, currentUser.id),
          ),
        ),
      );
    } else {
      if (_selectedChat?.id != chat.id) {
        _messagesNotifier.value = [];
        setState(() {
          _selectedChat = chat;
        });
      }
    }
  }

  Future<void> _openNewChatDialog(BuildContext context, UserModel currentUser, bool isMobile) async {
    final chat = await NewChatDialog.show(context, currentUser);
    if (chat != null && mounted) {
      _onSelectChat(context, chat, isMobile, currentUser);
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 768 && width < 1100;
        final isMobile = width < 768;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: EduStreakTheme.studentDarkBg,
          appBar: (widget.showAppBar && isMobile)
              ? AppBar(
                  backgroundColor: EduStreakTheme.studentDarkHeader,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: AppLogo(size: 26),
                  ),
                  title: const Text(
                    'EduStreak Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_comment_rounded, color: EduStreakTheme.primaryVioletLight),
                      tooltip: 'New Conversation',
                      onPressed: () => _openNewChatDialog(context, currentUser, isMobile),
                    ),
                  ],
                )
              : null,
          endDrawer: (isTablet && _selectedChat != null)
              ? Drawer(
                  backgroundColor: EduStreakTheme.studentDarkSidebar,
                  child: SafeArea(
                    child: ValueListenableBuilder<List<MessageModel>>(
                      valueListenable: _messagesNotifier,
                      builder: (context, messages, _) {
                        return ChatInfoPanel(
                          currentUser: currentUser,
                          chat: _selectedChat!,
                          messages: messages,
                          onClose: () => Navigator.of(context).pop(),
                          onToggleMute: () {
                            final isMuted = _selectedChat!.isMutedFor(currentUser.id);
                            _chatService.toggleMuteChat(
                              chatId: _selectedChat!.id,
                              userId: currentUser.id,
                              currentMuted: isMuted,
                            );
                          },
                          onTogglePin: () {
                            _chatService.togglePinChat(
                              chatId: _selectedChat!.id,
                              currentIsPinned: _selectedChat!.isPinned,
                            );
                          },
                        );
                      },
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: isMobile
                ? ConversationSidebar(
                    currentUser: currentUser,
                    selectedChatId: _selectedChat?.id,
                    isMobile: true,
                    onSelectChat: (chat) => _onSelectChat(context, chat, isMobile, currentUser),
                    onNewChat: () => _openNewChatDialog(context, currentUser, isMobile),
                  )
                : Row(
                    children: [
                      // Left Sidebar (Conversation List)
                      SizedBox(
                        width: isDesktop ? 350 : 320,
                        child: ConversationSidebar(
                          currentUser: currentUser,
                          selectedChatId: _selectedChat?.id,
                          isMobile: false,
                          onSelectChat: (chat) => _onSelectChat(context, chat, isMobile, currentUser),
                          onNewChat: () => _openNewChatDialog(context, currentUser, isMobile),
                        ),
                      ),

                      // Center Workstation Area (Chat Window or Empty Placeholder)
                      Expanded(
                        child: _selectedChat != null
                            ? ChatWindowView(
                                key: ValueKey('chat_window_${_selectedChat!.id}'),
                                currentUser: currentUser,
                                chat: _selectedChat!,
                                isMobile: false,
                                isInfoPanelOpen: _showInfoPanel,
                                messagesNotifier: _messagesNotifier,
                                onToggleInfoPanel: () {
                                  if (isTablet) {
                                    _scaffoldKey.currentState?.openEndDrawer();
                                  } else {
                                    setState(() => _showInfoPanel = !_showInfoPanel);
                                  }
                                },
                              )
                            : _buildEmptyWorkstation(context, currentUser, isMobile),
                      ),

                      // Right Info Panel (Desktop Only)
                      if (isDesktop && _selectedChat != null && _showInfoPanel)
                        SizedBox(
                          width: 300,
                          child: ValueListenableBuilder<List<MessageModel>>(
                            valueListenable: _messagesNotifier,
                            builder: (context, messages, _) {
                              return ChatInfoPanel(
                                currentUser: currentUser,
                                chat: _selectedChat!,
                                messages: messages,
                                onClose: () => setState(() => _showInfoPanel = false),
                                onToggleMute: () {
                                  final isMuted = _selectedChat!.isMutedFor(currentUser.id);
                                  _chatService.toggleMuteChat(
                                    chatId: _selectedChat!.id,
                                    userId: currentUser.id,
                                    currentMuted: isMuted,
                                  );
                                },
                                onTogglePin: () {
                                  _chatService.togglePinChat(
                                    chatId: _selectedChat!.id,
                                    currentIsPinned: _selectedChat!.isPinned,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWorkstation(BuildContext context, UserModel currentUser, bool isMobile) {
    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing circular logo container
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: EduStreakTheme.activePillGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: EduStreakTheme.primaryViolet.withAlpha((0.45 * 255).round()),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'EduStreak Messaging',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a conversation from the sidebar to chat, or start a new conversation with a teacher, student, or parent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EduStreakTheme.studentDarkTextMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openNewChatDialog(context, currentUser, isMobile),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: EduStreakTheme.activePillGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: EduStreakTheme.primaryViolet.withAlpha((0.35 * 255).round()),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_comment_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Start New Conversation',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
