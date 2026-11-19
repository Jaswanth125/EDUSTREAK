import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_assistant_models.dart';
import '../../providers/user_provider.dart';
import '../../services/study_assistant_service.dart';
import '../../utils/edustreak_theme.dart';

class StudyAssistantScreen extends StatefulWidget {
  final bool showAppBar;

  const StudyAssistantScreen({super.key, this.showAppBar = false});

  @override
  State<StudyAssistantScreen> createState() => _StudyAssistantScreenState();
}

class _StudyAssistantScreenState extends State<StudyAssistantScreen> {
  final StudyAssistantService _service = StudyAssistantService();

  bool _documentsLoading = true;
  bool _uploading = false;
  bool _chatSending = false;

  int? _vectorCount;
  List<StudyDocument> _documents = [];

  String _mode = 'chat';

  final TextEditingController _summaryTopicController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _quizTopicController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  final List<_ChatEntry> _chatLog = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDocuments(),
      _loadStatus(),
      _loadTopics(),
    ]);
  }

  Future<void> _loadDocuments() async {
    setState(() => _documentsLoading = true);
    try {
      final docs = await _service.fetchDocuments();
      if (!mounted) return;
      setState(() => _documents = docs);
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      // Non-blocking
    } finally {
      if (mounted) {
        setState(() => _documentsLoading = false);
      }
    }
  }

  Future<void> _loadStatus() async {
    try {
      final count = await _service.fetchVectorStoreCount();
      if (!mounted) return;
      setState(() => _vectorCount = count);
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> _loadTopics() async {
    try {
      await _service.fetchTopics();
    } catch (_) {
      // Non-blocking
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    setState(() => _uploading = true);
    try {
      final messages = await _service.uploadDocuments([file]);
      if (!mounted) return;
      await _loadDocuments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messages.isNotEmpty ? messages.first : 'Uploaded ${file.name} successfully.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      await _loadStatus();
      await _loadTopics();
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Failed to upload document.');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _sendChatMessage([String? customPrompt]) async {
    final text = (customPrompt ?? _chatController.text).trim();
    if (text.isEmpty) {
      return;
    }

    final historyPayload = _chatLog.map((entry) => entry.toPayload()).toList();

    setState(() {
      _chatLog.add(_ChatEntry(role: 'user', content: text));
      if (customPrompt == null) _chatController.clear();
      _chatSending = true;
    });

    try {
      final reply = await _service.chatWithTutor(
        message: text,
        conversationHistory: historyPayload,
      );
      if (!mounted) return;
      setState(() {
        _chatLog.add(_ChatEntry(role: 'assistant', content: reply));
      });
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _chatLog.add(const _ChatEntry(
            role: 'assistant',
            content: "I'm ready to help you learn! Feel free to ask questions about science, math, or upload your lesson notes anytime.",
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _chatSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;
    final studentName = currentUser?.name.trim().isNotEmpty == true ? currentUser!.name.trim().split(' ').first : 'Student';

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: RefreshIndicator(
        onRefresh: _loadAll,
        color: EduStreakTheme.primaryViolet,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Page Header (Robot + AI Study Buddy + Subtitle)
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. Hero Card: Robot Mascot + Hello Akash + Quick Action Pills
              _buildRobotHeroCard(studentName),
              const SizedBox(height: 20),

              // 3. Middle Row: "Try Asking" chips + "Your Study Assistant" feature card
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  if (width >= 860) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildTryAskingCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: _buildStudyAssistantFeaturesCard()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildTryAskingCard(),
                        const SizedBox(height: 16),
                        _buildStudyAssistantFeaturesCard(),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              // 4. Mode Selector Pill Tabs (Chat Tutor, Quizzes, Summaries, Knowledge Library)
              _buildModeSelector(),
              const SizedBox(height: 16),

              // 5. Active Mode Container
              if (_mode == 'chat') ...[
                _buildInteractiveChatFeed(),
                const SizedBox(height: 16),
                _buildChatInputField(),
              ] else if (_mode == 'library') ...[
                _buildDocumentCard(),
              ] else if (_mode == 'summary') ...[
                _buildSummarySection(),
              ] else ...[
                _buildQuizSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── PAGE HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: const Icon(Icons.smart_toy_rounded, color: EduStreakTheme.primaryViolet, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI Study Buddy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('🤖', style: TextStyle(fontSize: 18)),
                ],
              ),
              SizedBox(height: 2),
              Text(
                'Your personal AI learning companion — ask, learn and get instant help!',
                style: TextStyle(
                  color: EduStreakTheme.studentDarkTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── HERO CARD: ROBOT MASCOT + HELLO AKASH + QUICK ACTION PILLS ──────────
  Widget _buildRobotHeroCard(String studentName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Friendly Robot Mascot on Left
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7950FF).withValues(alpha: 0.2),
                      border: Border.all(color: const Color(0xFF7950FF), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Center Greeting & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $studentName! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How can I help you learn today?',
                          style: TextStyle(
                            color: EduStreakTheme.studentDarkHighlight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_vectorCount != null && _vectorCount! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '✓ $_vectorCount learning topics indexed & ready',
                              style: const TextStyle(
                                color: EduStreakTheme.neonCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 3D Glowing Open Book Artwork on Right
                  if (!isNarrow) ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const RadialGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7950FF), Colors.transparent],
                          stops: [0.15, 0.5, 1.0],
                        ),
                      ),
                      child: const Center(
                        child: Text('📖✨', style: TextStyle(fontSize: 34)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // 4 Quick Action Pills
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildQuickActionPill('💡 Explain a Topic', () {
                    _chatController.text = 'Can you explain Photosynthesis step by step?';
                    _sendChatMessage();
                  }),
                  _buildQuickActionPill('📝 Solve a Question', () {
                    _chatController.text = 'Help me solve: Find x if 3x + 7 = 22';
                    _sendChatMessage();
                  }),
                  _buildQuickActionPill('⚡ Generate Practice', () {
                    setState(() => _mode = 'quiz');
                  }),
                  _buildQuickActionPill('📅 Study Plan', () {
                    _chatController.text = 'Create a 5-day study plan for Class 8 Science & Maths';
                    _sendChatMessage();
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionPill(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkCardSub,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EduStreakTheme.studentDarkBorder),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ─── CARD: TRY ASKING PROMPT CHIPS (LEFT CARD) ───────────────────────────
  Widget _buildTryAskingCard() {
    final prompts = [
      'Explain photosynthesis in simple words',
      'Give 5 MCQs on Algebra',
      'Help me with my homework',
      'Create a study plan for this week',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💬', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'Try Asking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: prompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    _chatController.text = prompt;
                    _sendChatMessage(prompt);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.studentDarkCardSub,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EduStreakTheme.studentDarkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFFC4B5FD)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prompt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: EduStreakTheme.studentDarkHighlight),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── CARD: YOUR STUDY ASSISTANT (RIGHT CARD) ─────────────────────────────
  Widget _buildStudyAssistantFeaturesCard() {
    final features = [
      'Clear explanations',
      'Step-by-step solutions',
      'Practice questions',
      'Homework guidance',
      'Personalised study tips',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'Your Study Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...features.map((feat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 3D Glowing Lightbulb on Books Artwork
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const RadialGradient(
                colors: [Color(0xFFFBBF24), Color(0xFF7950FF), Colors.transparent],
                stops: [0.15, 0.5, 1.0],
              ),
            ),
            child: const Center(
              child: Text('💡📚', style: TextStyle(fontSize: 32)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM CHAT INPUT BAR ───────────────────────────────────────────────
  Widget _buildChatInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFC4B5FD), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Ask me anything about your studies...',
                hintStyle: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _sendChatMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: Color(0xFFC4B5FD), size: 20),
            tooltip: 'Voice Input',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listening... Ask your study question!'), backgroundColor: Color(0xFF7950FF)),
              );
            },
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _chatSending ? null : () => _sendChatMessage(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: EduStreakTheme.activePillGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7950FF).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _chatSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INTERACTIVE CHAT FEED ───────────────────────────────────────────────
  Widget _buildInteractiveChatFeed() {
    if (_chatLog.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Conversation Log',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              TextButton(
                onPressed: () => setState(() => _chatLog.clear()),
                child: const Text('Clear', style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _chatLog.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = _chatLog[index];
              final isUser = entry.role == 'user';

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF7950FF) : EduStreakTheme.studentDarkCardSub,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUser ? const Color(0xFFA855F7) : EduStreakTheme.studentDarkBorder,
                    ),
                  ),
                  child: Text(
                    entry.content,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── MODE SELECTOR TABS ──────────────────────────────────────────────────
  Widget _buildModeSelector() {
    final modes = [
      {'key': 'chat', 'label': 'AI Tutor Chat', 'icon': Icons.chat_rounded},
      {'key': 'library', 'label': 'Knowledge Library (${_documents.length})', 'icon': Icons.folder_rounded},
      {'key': 'summary', 'label': 'Summarizer', 'icon': Icons.summarize_rounded},
      {'key': 'quiz', 'label': 'Quiz Generator', 'icon': Icons.quiz_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modes.map((m) {
          final isSelected = _mode == m['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _mode = m['key'] as String),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7950FF) : EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFA855F7) : EduStreakTheme.studentDarkBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData, size: 15, color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted),
                    const SizedBox(width: 6),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── KNOWLEDGE LIBRARY (RAG DOCUMENT INGESTION) ──────────────────────────
  Widget _buildDocumentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Knowledge Library',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                onPressed: _documentsLoading ? null : _loadDocuments,
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload textbook chapters, lesson notes, and PDF study guides for personalized RAG assistance.',
            style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file_rounded),
            label: Text(_uploading ? 'Processing & Embedding...' : 'Upload Study Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7950FF),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          if (_documents.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              separatorBuilder: (_, __) => const Divider(color: EduStreakTheme.studentDarkBorder),
              itemBuilder: (_, index) {
                final doc = _documents[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(doc.filename, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('${doc.chunkCount} indexed chunks', style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 11)),
                  trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── SUMMARIES SECTION ───────────────────────────────────────────────────
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Instant Summary',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _summaryTopicController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter topic (e.g. Newton Laws, Cell Biology)',
              hintStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted),
              filled: true,
              fillColor: EduStreakTheme.studentDarkCardSub,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating summary from knowledge base...'), backgroundColor: Color(0xFF7950FF)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7950FF)),
            child: const Text('Summarize', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── QUIZ SECTION ────────────────────────────────────────────────────────
  Widget _buildQuizSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Practice Quiz',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _quizTopicController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter topic for quiz (e.g. Algebra Quadratic Equations)',
              hintStyle: const TextStyle(color: EduStreakTheme.studentDarkTextMuted),
              filled: true,
              fillColor: EduStreakTheme.studentDarkCardSub,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Building customized practice quiz with 5 questions...'), backgroundColor: Color(0xFF7950FF)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7950FF)),
            child: const Text('Create Quiz', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _summaryTopicController.dispose();
    _questionController.dispose();
    _quizTopicController.dispose();
    _chatController.dispose();
    super.dispose();
  }
}

class _ChatEntry {
  final String role;
  final String content;

  const _ChatEntry({required this.role, required this.content});

  Map<String, String> toPayload() => {'role': role, 'content': content};
}
