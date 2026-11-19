import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import '../../../services/realtime_chat_service.dart';
import '../../../utils/edustreak_theme.dart';

class NewChatDialog extends StatefulWidget {
  final UserModel currentUser;
  final Function(ChatModel chat)? onChatSelected;

  const NewChatDialog({
    super.key,
    required this.currentUser,
    this.onChatSelected,
  });

  static Future<ChatModel?> show(BuildContext context, UserModel currentUser) {
    return showDialog<ChatModel>(
      context: context,
      barrierColor: Colors.black.withAlpha((0.75 * 255).round()),
      builder: (context) => NewChatDialog(currentUser: currentUser),
    );
  }

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final RealtimeChatService _chatService = RealtimeChatService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allContacts = [];
  bool _isLoading = true;
  String _selectedRoleFilter = 'all'; // all, teacher, student, parent, principal

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await _chatService.getAvailableContacts(widget.currentUser);
    if (mounted) {
      setState(() {
        _allContacts = contacts;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    return _allContacts.where((contact) {
      final role = (contact['role'] as String? ?? '').toLowerCase();
      if (_selectedRoleFilter != 'all' && role != _selectedRoleFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final name = (contact['name'] as String? ?? '').toLowerCase();
      final email = (contact['email'] as String? ?? '').toLowerCase();
      final grade = (contact['grade'] as String? ?? '').toLowerCase();
      final section = (contact['section'] as String? ?? '').toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          grade.contains(query) ||
          section.contains(query);
    }).toList();
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

  Future<void> _selectContact(Map<String, dynamic> contact) async {
    final otherUserId = contact['id'] as String;
    final otherUserRole = (contact['role'] as String? ?? 'user').toLowerCase();
    final otherUserName = contact['name'] as String? ?? 'User';

    // Show quick progress overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
      ),
    );

    try {
      final chat = await _chatService.getOrCreateChat(
        currentUserId: widget.currentUser.id,
        currentUserRole: widget.currentUser.role,
        currentUserName: widget.currentUser.name,
        otherUserId: otherUserId,
        otherUserRole: otherUserRole,
        otherUserName: otherUserName,
        schoolId: widget.currentUser.schoolId,
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading indicator
        if (widget.onChatSelected != null) {
          widget.onChatSelected!(chat);
        }
        Navigator.of(context).pop(chat); // close dialog and return chat
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open conversation: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRoles = {'all'};
    for (final c in _allContacts) {
      final r = (c['role'] as String? ?? '').toLowerCase();
      if (r.isNotEmpty) availableRoles.add(r);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.6 * 255).round()),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: EduStreakTheme.primaryViolet.withAlpha((0.15 * 255).round()),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: EduStreakTheme.activePillGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Conversation',
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Select a contact to message securely',
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: EduStreakTheme.studentDarkBorder.withAlpha((0.5 * 255).round()),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, role, class or email...',
                    hintStyle: TextStyle(
                      color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.6 * 255).round()),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: EduStreakTheme.primaryVioletLight,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white54),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Role Filter Chips
            if (availableRoles.length > 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: availableRoles.map((roleKey) {
                      final isSelected = _selectedRoleFilter == roleKey;
                      final label = roleKey == 'all'
                          ? 'All Contacts'
                          : '${roleKey[0].toUpperCase()}${roleKey.substring(1)}s';
                      final color = roleKey == 'all'
                          ? EduStreakTheme.primaryViolet
                          : _getRoleColor(roleKey);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRoleFilter = roleKey),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withAlpha((0.25 * 255).round())
                                  : EduStreakTheme.studentDarkCardSub.withAlpha((0.5 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? color : EduStreakTheme.studentDarkBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Contacts List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                    )
                  : _filteredContacts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 48,
                                  color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.4 * 255).round()),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _allContacts.isEmpty
                                      ? 'No contacts found for your role'
                                      : 'No contacts match your search',
                                  style: const TextStyle(
                                    color: EduStreakTheme.studentDarkTextMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredContacts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            final name = contact['name'] as String? ?? 'User';
                            final role = (contact['role'] as String? ?? 'user').toLowerCase();
                            final email = contact['email'] as String? ?? '';
                            final grade = contact['grade'] as String? ?? '';
                            final section = contact['section'] as String? ?? '';
                            final subjects = (contact['assignedSubjects'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .toList() ??
                                [];
                            final roleColor = _getRoleColor(role);

                            String detailSub = email;
                            if (grade.isNotEmpty) {
                              detailSub = 'Class $grade${section.isNotEmpty ? '-$section' : ''} • $email';
                            } else if (subjects.isNotEmpty) {
                              detailSub = '${subjects.join(", ")} • $email';
                            }

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => _selectContact(contact),
                                borderRadius: BorderRadius.circular(14),
                                hoverColor: EduStreakTheme.primaryViolet.withAlpha((0.15 * 255).round()),
                                splashColor: EduStreakTheme.primaryViolet.withAlpha((0.25 * 255).round()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: EduStreakTheme.studentDarkCardSub.withAlpha((0.5 * 255).round()),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: EduStreakTheme.studentDarkBorder.withAlpha((0.3 * 255).round()),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              roleColor.withAlpha((0.8 * 255).round()),
                                              roleColor.withAlpha((0.4 * 255).round()),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: roleColor.withAlpha((0.2 * 255).round()),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Name & Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: roleColor.withAlpha((0.18 * 255).round()),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: roleColor.withAlpha((0.4 * 255).round()),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    role.toUpperCase(),
                                                    style: TextStyle(
                                                      color: roleColor,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              detailSub,
                                              style: TextStyle(
                                                color: EduStreakTheme.studentDarkTextMuted,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: EduStreakTheme.primaryViolet.withAlpha((0.15 * 255).round()),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: EduStreakTheme.primaryVioletLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
