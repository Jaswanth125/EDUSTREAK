import 'package:flutter/material.dart';

import '../chat/realtime_chat_list_screen.dart';

class ParentChatScreen extends StatelessWidget {
  const ParentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RealtimeChatListScreen(showAppBar: false);
  }
}

