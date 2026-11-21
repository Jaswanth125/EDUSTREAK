import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import '../../../models/message_model.dart';
import '../../../services/realtime_chat_service.dart';
import '../../../utils/edustreak_theme.dart';

class ChatMessageComposer extends StatefulWidget {
  final String chatId;
  final MessageModel? replyToMessage;
  final VoidCallback onCancelReply;
  final Function({
    required String text,
    String type,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
  }) onSendMessage;
  final Function(bool isTyping)? onTypingStatusChanged;

  const ChatMessageComposer({
    super.key,
    required this.chatId,
    required this.replyToMessage,
    required this.onCancelReply,
    required this.onSendMessage,
    this.onTypingStatusChanged,
  });

  @override
  State<ChatMessageComposer> createState() => _ChatMessageComposerState();
}

class _ChatMessageComposerState extends State<ChatMessageComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final RealtimeChatService _chatService = RealtimeChatService();

  bool _showEmojiShelf = false;
  bool _isUploadingAttachment = false;
  bool _isSending = false;
  Map<String, dynamic>? _selectedAttachment;
  Timer? _typingTimer;
  bool _wasTyping = false;

  final List<String> _quickEmojis = [
    '👍', '❤️', '👏', '🙏', '😊', '🎯', '🔥', '🎉', '📚', '✨', '💡', '✅'
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText) {
      if (!_wasTyping) {
        _wasTyping = true;
        widget.onTypingStatusChanged?.call(true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _wasTyping = false;
          widget.onTypingStatusChanged?.call(false);
        }
      });
    } else if (_wasTyping) {
      _wasTyping = false;
      _typingTimer?.cancel();
      widget.onTypingStatusChanged?.call(false);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_wasTyping) {
      widget.onTypingStatusChanged?.call(false);
    }
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          // Allow shift+enter for newline
          return KeyEventResult.ignored;
        } else {
          // Enter to send
          _handleSend();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handleSend() async {
    if (_isUploadingAttachment || _isSending) return;
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    _typingTimer?.cancel();
    if (_wasTyping) {
      _wasTyping = false;
      widget.onTypingStatusChanged?.call(false);
    }

    final att = _selectedAttachment;
    setState(() => _isSending = true);

    try {
      await widget.onSendMessage(
        text: text,
        type: att?['type'] ?? 'text',
        attachmentUrl: att?['url'],
        attachmentName: att?['name'],
        attachmentSize: att?['size'],
      );

      _textController.clear();
      if (mounted) {
        setState(() {
          _selectedAttachment = null;
          _showEmojiShelf = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _focusNode.requestFocus();
      }
    }
  }

  Future<void> _pickAttachment(String type) async {
    try {
      final isImage = type == 'image';
      final result = await FilePicker.platform.pickFiles(
        type: isImage ? FileType.image : FileType.custom,
        allowedExtensions: isImage ? null : ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      final fileName = pickedFile.name;
      final fileSize = pickedFile.size;

      // 15MB limit check
      if (fileSize > 15 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size exceeds the 15MB limit. Please choose a smaller file.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      Uint8List? fileBytes = pickedFile.bytes;
      if (fileBytes == null && !kIsWeb && pickedFile.path != null) {
        fileBytes = await io.File(pickedFile.path!).readAsBytes();
      }

      if (fileBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not read file data. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingAttachment = true);

      final ext = fileName.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(ext)) {
        contentType = 'image/jpeg';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'txt') {
        contentType = 'text/plain';
      }

      final downloadUrl = await _chatService.uploadChatAttachment(
        chatId: widget.chatId,
        fileName: fileName,
        bytes: fileBytes,
        contentType: contentType,
      );

      if (!mounted) return;
      setState(() => _isUploadingAttachment = false);

      if (downloadUrl != null) {
        setState(() {
          _selectedAttachment = {
            'type': isImage ? 'image' : 'file',
            'url': downloadUrl,
            'name': fileName,
            'size': fileSize,
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload attachment. Please check your connection and try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting attachment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = selection.textBefore(text) + emoji + selection.textAfter(text);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: selection.baseOffset + emoji.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_isUploadingAttachment && !_isSending &&
        (_textController.text.trim().isNotEmpty || _selectedAttachment != null);

    return Container(
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkHeader,
        border: Border(
          top: BorderSide(
            color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Uploading banner
          if (_isUploadingAttachment) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EduStreakTheme.studentDarkCard,
              child: Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EduStreakTheme.primaryViolet,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Uploading attachment to secure storage...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
          ],
          // Reply preview banner
          if (widget.replyToMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EduStreakTheme.studentDarkCardSub.withAlpha((0.85 * 255).round()),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 36,
                    decoration: BoxDecoration(
                      color: EduStreakTheme.primaryViolet,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.reply_rounded,
                              size: 13,
                              color: EduStreakTheme.primaryVioletLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to ${widget.replyToMessage!.senderName ?? "Message"}',
                              style: const TextStyle(
                                color: EduStreakTheme.primaryVioletLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.replyToMessage!.text.isNotEmpty
                              ? widget.replyToMessage!.text
                              : (widget.replyToMessage!.attachmentName ?? 'Attachment'),
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                    onPressed: widget.onCancelReply,
                    tooltip: 'Cancel Reply',
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
          ],

          // Attachment preview banner
          if (_selectedAttachment != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: EduStreakTheme.studentDarkCard,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.primaryViolet.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedAttachment!['type'] == 'image'
                          ? Icons.image_rounded
                          : Icons.insert_drive_file_rounded,
                      color: EduStreakTheme.neonCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAttachment!['name'] ?? 'File',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${((_selectedAttachment!['size'] as int? ?? 0) / 1024).round()} KB • Ready to send',
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => setState(() => _selectedAttachment = null),
                    tooltip: 'Remove Attachment',
                  ),
                ],
              ),
            ),
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
          ],

          // Quick Emoji Shelf
          if (_showEmojiShelf) ...[
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: EduStreakTheme.studentDarkCardSub,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _quickEmojis[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: InkWell(
                      onTap: () => _insertEmoji(emoji),
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: EduStreakTheme.primaryViolet.withAlpha((0.2 * 255).round()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: EduStreakTheme.studentDarkBorder, height: 1),
          ],

          // Input Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick emoji toggle button
                IconButton(
                  icon: Icon(
                    _showEmojiShelf ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                    color: _showEmojiShelf
                        ? EduStreakTheme.primaryVioletLight
                        : EduStreakTheme.studentDarkTextMuted,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _showEmojiShelf = !_showEmojiShelf),
                  tooltip: 'Quick Reactions & Emojis',
                  splashRadius: 20,
                ),

                // Attachment Popup Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: EduStreakTheme.studentDarkTextMuted,
                    size: 22,
                  ),
                  tooltip: 'Attach File or Image',
                  color: EduStreakTheme.studentDarkCard,
                  shape: RoundedRectangle68Border(),
                  offset: const Offset(0, -110),
                  onSelected: _pickAttachment,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'image',
                      child: Row(
                        children: const [
                          Icon(Icons.photo_library_rounded, color: EduStreakTheme.neonCyan, size: 20),
                          SizedBox(width: 10),
                          Text('Photo / Image', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'file',
                      child: Row(
                        children: const [
                          Icon(Icons.description_rounded, color: EduStreakTheme.emeraldGreen, size: 20),
                          SizedBox(width: 10),
                          Text('Document (PDF/DOC)', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                // Text Field
                Expanded(
                  child: Focus(
                    focusNode: _focusNode,
                    onKeyEvent: _handleKeyEvent,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.studentDarkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EduStreakTheme.studentDarkBorder.withAlpha((0.6 * 255).round()),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message... (Enter to send, Shift+Enter for new line)',
                          hintStyle: TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted.withAlpha((0.5 * 255).round()),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Gradient Send Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canSend ? _handleSend : null,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: canSend
                            ? EduStreakTheme.activePillGradient
                            : LinearGradient(
                                colors: [
                                  EduStreakTheme.studentDarkCardSub,
                                  EduStreakTheme.studentDarkCardSub,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canSend
                            ? [
                                BoxShadow(
                                  color: EduStreakTheme.primaryViolet.withAlpha((0.4 * 255).round()),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: canSend ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                                size: 20,
                              ),
                      ),
                    ),
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

class RoundedRectangle68Border extends RoundedRectangleBorder {
  RoundedRectangle68Border()
      : super(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: EduStreakTheme.studentDarkBorder.withAlpha((0.8 * 255).round()),
          ),
        );
}
