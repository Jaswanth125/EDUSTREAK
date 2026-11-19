import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/edustreak_theme.dart';

class ChatInfoPanel extends StatelessWidget {
  final UserModel currentUser;
  final ChatModel chat;
  final List<MessageModel> messages;
  final VoidCallback? onClose;
  final VoidCallback? onToggleMute;
  final VoidCallback? onTogglePin;

  const ChatInfoPanel({
    super.key,
    required this.currentUser,
    required this.chat,
    required this.messages,
    this.onClose,
    this.onToggleMute,
    this.onTogglePin,
  });

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
                errorBuilder: (_, __, ___) => Container(
                  width: 300,
                  height: 300,
                  color: EduStreakTheme.studentDarkCard,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                  ),
                ),
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
    final otherName = chat.getOtherParticipantName(currentUser.id);
    final otherRole = chat.getOtherParticipantRole(currentUser.id);
    final roleColor = _getRoleColor(otherRole);
    final isMuted = chat.isMutedFor(currentUser.id);
    final isPinned = chat.isPinned;

    final mediaMessages = messages
        .where((m) => m.type == 'image' && m.attachmentUrl != null && !m.isDeleted)
        .toList();

    final fileMessages = messages
        .where((m) => m.type == 'file' && m.attachmentName != null && !m.isDeleted)
        .toList();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkSidebar,
        border: Border(
          left: BorderSide(
            color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: EduStreakTheme.primaryVioletLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chat Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: onClose,
                    tooltip: 'Close Details Panel',
                    splashRadius: 18,
                  ),
              ],
            ),
          ),

          const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Profile Card
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              roleColor,
                              roleColor.withAlpha((0.5 * 255).round()),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: roleColor.withAlpha((0.35 * 255).round()),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        otherName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha((0.15 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: roleColor.withAlpha((0.4 * 255).round()),
                          ),
                        ),
                        child: Text(
                          otherRole.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Action Cards
                Container(
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: EduStreakTheme.studentDarkBorder.withAlpha((0.5 * 255).round()),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: Icon(
                          isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                          color: EduStreakTheme.primaryVioletLight,
                          size: 20,
                        ),
                        title: Text(
                          isPinned ? 'Pinned to Top' : 'Pin Conversation',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        trailing: Switch(
                          value: isPinned,
                          activeThumbColor: EduStreakTheme.primaryViolet,
                          onChanged: (_) => onTogglePin?.call(),
                        ),
                      ),
                      const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          isMuted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                          color: isMuted ? Colors.orangeAccent : EduStreakTheme.neonCyan,
                          size: 20,
                        ),
                        title: Text(
                          isMuted ? 'Muted' : 'Notifications',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        trailing: Switch(
                          value: !isMuted,
                          activeThumbColor: EduStreakTheme.primaryViolet,
                          onChanged: (_) => onToggleMute?.call(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Shared Media Section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Shared Photos (${mediaMessages.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 10),
                if (mediaMessages.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard.withAlpha((0.5 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No photos shared yet',
                      style: TextStyle(
                        color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.6 * 255).round()),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: mediaMessages.length > 6 ? 6 : mediaMessages.length,
                    itemBuilder: (context, index) {
                      final url = mediaMessages[index].attachmentUrl!;
                      return InkWell(
                        onTap: () => _previewImage(context, url),
                        borderRadius: BorderRadius.circular(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: EduStreakTheme.studentDarkCardSub,
                              child: const Icon(Icons.broken_image, size: 18, color: Colors.white30),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Shared Documents Section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Shared Documents (${fileMessages.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.attach_file_rounded, size: 16, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 10),
                if (fileMessages.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCard.withAlpha((0.5 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No documents shared yet',
                      style: TextStyle(
                        color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.6 * 255).round()),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Column(
                    children: fileMessages.take(4).map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EduStreakTheme.studentDarkCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: EduStreakTheme.studentDarkBorder.withAlpha((0.4 * 255).round()),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_rounded,
                                color: EduStreakTheme.emeraldGreen,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.attachmentName ?? 'Document',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${((f.attachmentSize ?? 0) / 1024).round()} KB',
                                      style: TextStyle(
                                        color: EduStreakTheme.studentDarkTextMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.download_rounded,
                                color: EduStreakTheme.neonCyan,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 30),

                // Privacy Shield Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCardSub.withAlpha((0.4 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: EduStreakTheme.primaryViolet.withAlpha((0.25 * 255).round()),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: EduStreakTheme.primaryVioletLight,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'End-to-end encrypted school communication.',
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
