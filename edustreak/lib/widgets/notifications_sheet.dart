import 'package:flutter/material.dart';
import '../models/in_app_notification_model.dart';
import '../screens/chat/realtime_chat_screen.dart';
import '../services/in_app_notification_service.dart';
import '../utils/edustreak_theme.dart';

/// Modal bottom sheet or dialog to display live notifications.
class NotificationsSheet extends StatelessWidget {
  final String userId;
  final bool isDark;

  const NotificationsSheet({
    super.key,
    required this.userId,
    this.isDark = true,
  });

  static Future<void> show(BuildContext context, {required String userId, bool isDark = true}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(userId: userId, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = InAppNotificationService();
    final bg = isDark ? EduStreakTheme.studentDarkBg : Colors.white;
    final cardBg = isDark ? EduStreakTheme.studentDarkCard : const Color(0xFFF8F9FE);
    final border = isDark ? EduStreakTheme.studentDarkBorder : const Color(0xFFE2E8F0);
    final textCol = isDark ? Colors.white : const Color(0xFF1E293B);
    final textMuted = isDark ? EduStreakTheme.studentDarkTextMuted : const Color(0xFF64748B);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.primaryViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: EduStreakTheme.primaryViolet, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: textCol,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => notificationService.markAllAsRead(userId),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: EduStreakTheme.primaryViolet,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification List Stream
          Expanded(
            child: StreamBuilder<List<InAppNotificationModel>>(
              stream: notificationService.streamNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 54, color: textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            "You're all caught up!",
                            style: TextStyle(
                              color: textCol,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "New assignments, grades, and XP rewards will appear here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _buildNotificationItem(context, item, cardBg, border, textCol, textMuted, notificationService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    InAppNotificationModel item,
    Color cardBg,
    Color border,
    Color textCol,
    Color textMuted,
    InAppNotificationService service,
  ) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case 'homework':
        icon = Icons.assignment_rounded;
        iconColor = const Color(0xFF38BDF8);
        break;
      case 'grade':
        icon = Icons.verified_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'badge':
        icon = Icons.emoji_events_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
      case 'level_up':
        icon = Icons.rocket_launch_rounded;
        iconColor = const Color(0xFFA855F7);
        break;
      case 'xp':
        icon = Icons.bolt_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'attendance':
        icon = Icons.event_available_rounded;
        iconColor = const Color(0xFF06B6D4);
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        iconColor = const Color(0xFF8B5CF6);
        break;
      default:
        icon = Icons.info_rounded;
        iconColor = EduStreakTheme.primaryViolet;
    }

    final timeAgo = _formatTimeAgo(item.createdAt);

    return InkWell(
      onTap: () {
        if (!item.isRead) {
          service.markAsRead(item.id);
        }
        if (item.type == 'message' && item.metadata != null && item.metadata!['chatId'] != null) {
          final chatId = item.metadata!['chatId'].toString();
          final senderId = item.metadata!['senderId']?.toString() ?? '';
          final senderName = item.metadata!['senderName']?.toString() ?? 'User';
          final senderRole = item.metadata!['senderRole']?.toString() ?? 'user';
          Navigator.pop(context); // Close notification sheet
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RealtimeChatScreen(
                chatId: chatId,
                otherUserId: senderId,
                otherUserName: senderName,
                otherUserRole: senderRole,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? cardBg.withValues(alpha: 0.6) : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? border : EduStreakTheme.primaryViolet.withValues(alpha: 0.5),
            width: item.isRead ? 1 : 1.4,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: textCol,
                            fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EduStreakTheme.primaryViolet,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
