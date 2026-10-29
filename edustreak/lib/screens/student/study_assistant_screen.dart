import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/study_assistant_models.dart';
import '../../providers/user_provider.dart';
import '../../services/study_assistant_service.dart';
import '../../utils/theme.dart';

class StudyAssistantScreen extends StatefulWidget {
  final bool showAppBar;

  const StudyAssistantScreen({super.key, this.showAppBar = true});

  @override
  State<StudyAssistantScreen> createState() => _StudyAssistantScreenState();
}

class _StudyAssistantScreenState extends State<StudyAssistantScreen> {
  final StudyAssistantService _service = StudyAssistantService();

  bool _documentsLoading = true;
  bool _statusLoading = true;
  bool _topicsLoading = true;
  bool _uploading = false;
  bool _summaryLoading = false;
  bool _questionLoading = false;
  bool _quizLoading = false;
  bool _chatSending = false;

  int? _vectorCount;
  List<StudyDocument> _documents = [];
  List<String> _selectedDocuments = [];
  List<String> _topics = [];

  String _mode = 'summary';
  String _summaryType = 'all';
  int _quizQuestionCount = 5;

  StudySummaryResult? _summaryResult;
  StudyAnswerResult? _answerResult;
  StudyQuiz? _currentQuiz;
  bool _quizSubmitted = false;
  double? _quizScore;
  final Map<int, String> _quizAnswers = {};

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
      _showError('Failed to load documents.');
    } finally {
      if (mounted) {
        setState(() => _documentsLoading = false);
      }
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _statusLoading = true);
    try {
      final count = await _service.fetchVectorStoreCount();
      if (!mounted) return;
      setState(() => _vectorCount = count);
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Failed to load status.');
    } finally {
      if (mounted) {
        setState(() => _statusLoading = false);
      }
    }
  }

  Future<void> _loadTopics() async {
    setState(() => _topicsLoading = true);
    try {
      final topics = await _service.fetchTopics();
      if (!mounted) return;
      setState(() => _topics = topics);
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Failed to load topics.');
    } finally {
      if (mounted) {
        setState(() => _topicsLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        withReadStream: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'txt', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _uploading = true);
      final responses = await _service.uploadDocuments(result.files);
      if (responses.isNotEmpty) {
        _showSuccess(responses.join('\n'));
      }
      await Future.wait([
        _loadDocuments(),
        _loadStatus(),
      ]);
      await _loadTopics();
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Failed to upload documents.');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _generateSummary() async {
    final isFullSummary = _summaryType == 'all';
    final topic = _summaryTopicController.text.trim();

    if (!isFullSummary && topic.isEmpty) {
      _showError('Please enter or select a topic to summarize.');
      return;
    }

    setState(() {
      _summaryLoading = true;
      _summaryResult = null;
    });

    try {
      final result = await _service.generateSummary(
        topic: isFullSummary ? '' : topic,
        selectedDocuments: _selectedDocuments,
      );
      if (!mounted) return;
      setState(() => _summaryResult = result);
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to generate summary.');
    } finally {
      if (mounted) {
        setState(() => _summaryLoading = false);
      }
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showError('Please enter a question.');
      return;
    }

    setState(() {
      _questionLoading = true;
      _answerResult = null;
    });

    try {
      final result = await _service.askQuestion(
        question: question,
        selectedDocuments: _selectedDocuments,
      );
      if (!mounted) return;
      setState(() => _answerResult = result);
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to process the question.');
    } finally {
      if (mounted) {
        setState(() => _questionLoading = false);
      }
    }
  }

  Future<void> _generateQuiz() async {
    final topic = _quizTopicController.text.trim();
    if (topic.isEmpty) {
      _showError('Please enter a topic for the quiz.');
      return;
    }

    setState(() {
      _quizLoading = true;
      _quizSubmitted = false;
      _quizScore = null;
      _quizAnswers.clear();
      _currentQuiz = null;
    });

    try {
      final quiz = await _service.generateQuiz(
        topic: topic,
        numberOfQuestions: _quizQuestionCount,
        selectedDocuments: _selectedDocuments,
      );
      if (!mounted) return;
      setState(() => _currentQuiz = quiz);
    } on StudyAssistantException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to generate quiz.');
    } finally {
      if (mounted) {
        setState(() => _quizLoading = false);
      }
    }
  }

  void _submitQuiz() {
    final quiz = _currentQuiz;
    if (quiz == null) return;
    if (_quizAnswers.length < quiz.questions.length) {
      _showError('Please answer all questions before submitting.');
      return;
    }

    int correct = 0;
    for (final question in quiz.questions) {
      final selected = _quizAnswers[question.id];
      if (selected != null && selected == question.correctAnswer) {
        correct++;
      }
    }

    final scorePercent = (correct / quiz.questions.length) * 100;
    setState(() {
      _quizSubmitted = true;
      _quizScore = scorePercent;
    });
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final historyPayload = _chatLog.map((entry) => entry.toPayload()).toList();

    setState(() {
      _chatLog.add(_ChatEntry(role: 'user', content: text));
      _chatController.clear();
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
      _showError('Unable to send message.');
    } finally {
      if (mounted) {
        setState(() => _chatSending = false);
      }
    }
  }

  void _toggleDocumentSelection(String filename) {
    setState(() {
      if (_selectedDocuments.contains(filename)) {
        _selectedDocuments.remove(filename);
      } else {
        _selectedDocuments.add(filename);
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM d, yyyy • HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final content = RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(currentUser.name),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildDocumentCard(),
            const SizedBox(height: 16),
            _buildModeSelector(),
            const SizedBox(height: 16),
            if (_mode == 'summary') ...[
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildQuestionCard(),
            ] else if (_mode == 'quiz') ...[
              _buildQuizCard(),
            ] else ...[
              _buildChatCard(),
            ],
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Assistant'),
        ),
        backgroundColor: AppTheme.darkBackground,
        body: content,
      );
    }

    return Container(
      color: AppTheme.darkBackground,
      child: content,
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardGlowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi $name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload your study material once and generate instant summaries, quizzes, and AI answers anytime.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your AI tutor is ready to help! Ask questions, get summaries, or take quizzes.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return _buildSurfaceCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Icon(Icons.cloud_done, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vector Store Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                if (_statusLoading)
                  const LinearProgressIndicator(minHeight: 4)
                else
                  Text(
                    _vectorCount == null
                        ? 'Ready to ingest documents'
                        : 'Indexed Chunks: $_vectorCount',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _statusLoading ? null : _loadStatus,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Knowledge Library',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _documentsLoading ? null : _loadDocuments,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Refresh documents',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload PDF, DOCX, or TXT files once. EduStreak will handle chunking, embeddings, and storage automatically.',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_uploading ? 'Uploading...' : 'Upload Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          _documentsLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _documents.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.auto_stories,
                      message: 'No documents uploaded yet.',
                      helper:
                          'Click "Upload Documents" above to ingest your first study file.',
                    )
                  : Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documents.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          itemBuilder: (_, index) {
                            final doc = _documents[index];
                            final selected = _selectedDocuments.contains(doc.filename);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                doc.filename,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${doc.chunkCount} chunks • ${_formatDate(doc.uploadedAt)}',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  selected ? Icons.check_circle : Icons.circle_outlined,
                                  color: selected ? AppTheme.primaryColor : Colors.white54,
                                ),
                                onPressed: () => _toggleDocumentSelection(doc.filename),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Use all documents'),
                                selected: _selectedDocuments.isEmpty,
                                onSelected: (_) => setState(() => _selectedDocuments = []),
                              ),
                              ..._documents.map(
                                (doc) => FilterChip(
                                  label: Text(doc.filename),
                                  selected: _selectedDocuments.contains(doc.filename),
                                  onSelected: (_) => _toggleDocumentSelection(doc.filename),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return _buildSurfaceCard(
      child: Wrap(
        spacing: 8,
        children: [
          _buildModeChip('summary', 'Summaries'),
          _buildModeChip('quiz', 'Quizzes'),
          _buildModeChip('chat', 'AI Tutor'),
        ],
      ),
    );
  }

  Widget _buildModeChip(String value, String label) {
    final isSelected = _mode == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _mode = value),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      selectedColor: Colors.white,
      backgroundColor: Colors.white12,
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white24,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instant Summaries',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSummaryTypeChip('all', 'Full Library'),
              _buildSummaryTypeChip('topic', 'Specific Topic'),
            ],
          ),
          if (_summaryType == 'topic') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _summaryTopicController,
              decoration: const InputDecoration(
                labelText: 'Topic to summarize',
                hintText: 'e.g. Photosynthesis, Electric circuits',
              ),
            ),
            const SizedBox(height: 10),
            if (_topicsLoading)
              const LinearProgressIndicator(minHeight: 3)
            else if (_topics.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topics.take(8).map((topic) {
                  return ActionChip(
                    label: Text(topic),
                    onPressed: () => setState(() {
                      _summaryTopicController.text = topic;
                    }),
                  );
                }).toList(),
              ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _summaryLoading ? null : _generateSummary,
            icon: _summaryLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_summaryLoading ? 'Generating...' : 'Generate Summary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          if (_summaryResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _summaryResult!.topic,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _summaryResult!.summary,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask a Question',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your question',
              hintText: 'e.g. Explain how current flows in a parallel circuit',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _questionLoading ? null : _askQuestion,
            icon: _questionLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_alt),
            label: Text(_questionLoading ? 'Thinking...' : 'Get Answer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.shade700,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          if (_answerResult != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.greenAccent.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'Confidence: ${_answerResult!.score.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _answerResult!.answer,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    collapsedIconColor: Colors.white54,
                    iconColor: Colors.white,
                    title: const Text(
                      'Show referenced context',
                      style: TextStyle(color: Colors.white70),
                    ),
                    children: [
                      Text(
                        _answerResult!.context,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Practice Quiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quizTopicController,
            decoration: const InputDecoration(
              labelText: 'Quiz topic',
              hintText: 'e.g. Force & Pressure, Photosynthesis',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questions: $_quizQuestionCount',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: _quizQuestionCount.toDouble(),
                      onChanged: (value) => setState(() {
                        _quizQuestionCount = value.toInt();
                      }),
                      min: 3,
                      max: 10,
                      divisions: 7,
                      label: _quizQuestionCount.toString(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.topic, color: Colors.white70),
                tooltip: 'Use suggested topic',
                onPressed: _topics.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _quizTopicController.text = _topics.first;
                        });
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _quizLoading ? null : _generateQuiz,
            icon: _quizLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.quiz),
            label: Text(_quizLoading ? 'Generating...' : 'Generate Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          if (_currentQuiz != null) ...[
            if (_quizScore != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Score: ${_quizScore!.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ListView.builder(
              itemCount: _currentQuiz!.questions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, index) {
                final question = _currentQuiz!.questions[index];
                return _buildQuizQuestion(question);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _quizSubmitted ? null : _submitQuiz,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Submit Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade400,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizQuestion(StudyQuizQuestion question) {
    final selected = _quizAnswers[question.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${question.id}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.entries.map(
            (entry) {
              final value = entry.key;
              final text = entry.value;
              final isCorrect = question.correctAnswer == value;
              final isSelected = selected == value;
              Color? tileColor;
              if (_quizSubmitted && isCorrect) {
                tileColor = Colors.greenAccent.withValues(alpha: 0.2);
              } else if (_quizSubmitted && isSelected && !isCorrect) {
                tileColor = Colors.redAccent.withValues(alpha: 0.2);
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: tileColor ?? Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<String>(
                  value: value,
                  groupValue: selected,
                  onChanged: _quizSubmitted
                      ? null
                      : (val) => setState(() => _quizAnswers[question.id] = val ?? ''),
                  title: Text(
                    '$value) $text',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_quizSubmitted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Explanation: ${question.explanation}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatCard() {
    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Tutor Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about your study material and get instant answers!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: _chatLog.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.chat_bubble_outline,
                      message: 'Start a conversation with your AI tutor!',
                      helper: 'Try asking: "Explain photosynthesis" or "What are the main points in chapter 3?"',
                    )
                  : ListView.builder(
                      itemCount: _chatLog.length,
                      itemBuilder: (_, index) {
                        final entry = _chatLog[index];
                        final isUser = entry.role == 'user';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  decoration: BoxDecoration(
                                    gradient: isUser
                                        ? AppTheme.primaryGradient
                                        : null,
                                    color: isUser
                                        ? null
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: isUser
                                        ? null
                                        : Border.all(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                  ),
                                  child: Text(
                                    entry.content,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ask your question...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.primaryGlowShadow,
                ),
                child: IconButton(
                  onPressed: _chatSending ? null : _sendChatMessage,
                  icon: _chatSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  tooltip: 'Send message',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTypeChip(String value, String label) {
    final isSelected = _summaryType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _summaryType = value),
      selectedColor: Colors.white,
      backgroundColor: Colors.white12,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? helper,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white30, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper,
              style: TextStyle(color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSurfaceCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: AppTheme.cardGlowShadow,
      ),
      child: child,
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
  final String role; // 'user' or 'assistant'
  final String content;

  const _ChatEntry({
    required this.role,
    required this.content,
  });

  Map<String, String> toPayload() => {
        'role': role,
        'content': content,
      };
}

