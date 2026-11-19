import 'package:flutter/material.dart';
import 'realtime_chat_list_screen.dart';

/// Unified chat inbox screen delegating directly to RealtimeChatListScreen
/// to ensure consistent multi-portal messaging using the chats collection.
class ChatInboxScreen extends StatelessWidget {
  final bool showAppBar;

  const ChatInboxScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return RealtimeChatListScreen(showAppBar: showAppBar);
  }
}
