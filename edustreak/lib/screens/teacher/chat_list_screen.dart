import 'package:flutter/material.dart';

import '../chat/realtime_chat_list_screen.dart';

class ChatListScreen extends StatelessWidget {
  final bool showAppBar;
  const ChatListScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    return RealtimeChatListScreen(showAppBar: showAppBar);
  }
}

