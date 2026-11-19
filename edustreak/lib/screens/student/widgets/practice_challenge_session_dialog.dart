import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/gamification_service.dart';
import '../../../services/skill_intelligence_service.dart';
import '../../../services/challenge_service.dart';
import '../../../utils/edustreak_theme.dart';

class ChallengeQuestion {
  final String id;
  final String subject;
  final String topic;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const ChallengeQuestion({
    required this.id,
    required this.subject,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class PracticeChallengeSessionDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String classId;
  final String? schoolId;
  final String challengeTitle;
  final String subject;
  final String? topic;
  final int totalQuestions;
  final int xpReward;
  final String? challengeId;
  final bool enableTimer;

  const PracticeChallengeSessionDialog({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.classId,
    this.schoolId,
    this.challengeTitle = 'Daily Practice Challenge',
    this.subject = 'Mixed Quiz',
    this.topic,
    this.totalQuestions = 5,
    this.xpReward = 50,
    this.challengeId,
    this.enableTimer = true,
  });

  static Future<void> start(
    BuildContext context, {
    required String studentId,
    required String studentName,
    required String classId,
    String? schoolId,
    String challengeTitle = 'Daily Practice Challenge',
    String subject = 'Mixed Quiz',
    String? topic,
    int totalQuestions = 5,
    int xpReward = 50,
    String? challengeId,
    bool enableTimer = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PracticeChallengeSessionDialog(
        studentId: studentId,
        studentName: studentName,
        classId: classId,
        schoolId: schoolId,
        challengeTitle: challengeTitle,
        subject: subject,
        topic: topic,
        totalQuestions: totalQuestions,
        xpReward: xpReward,
        challengeId: challengeId,
        enableTimer: enableTimer,
      ),
    );
  }

  @override
  State<PracticeChallengeSessionDialog> createState() => _PracticeChallengeSessionDialogState();
}

class _PracticeChallengeSessionDialogState extends State<PracticeChallengeSessionDialog> {
  final GamificationService _gamificationService = GamificationService();
  final ChallengeService _challengeService = ChallengeService();

  bool _isLoadingQuestions = true;
  List<ChallengeQuestion> _questions = [];
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};

  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes default
  bool _isSubmitted = false;
  bool _isSavingResults = false;
  int _correctCount = 0;
  int _earnedXp = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    final schoolId = widget.schoolId ?? 'school_ap_01';

    try {
      final List<ChallengeQuestion> loaded = [];

      // 1. Try to load approved AI tasks for this school/class
      try {
        final query = await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('ai_generated_tasks')
            .limit(15)
            .get();

        for (var doc in query.docs) {
          final data = doc.data();
          final qText = data['question']?.toString() ?? '';
          final opts = List<String>.from(data['options'] ?? []);
          final correct = data['correctAnswer']?.toString() ?? '';
          final exp = data['explanation']?.toString() ?? '';

          if (qText.isNotEmpty && opts.isNotEmpty && correct.isNotEmpty) {
            loaded.add(
              ChallengeQuestion(
                id: doc.id,
                subject: data['subject']?.toString() ?? widget.subject,
                topic: data['topic']?.toString() ?? 'Core Concept',
                question: qText,
                options: opts,
                correctAnswer: correct,
                explanation: exp.isNotEmpty ? exp : 'Correct answer is $correct.',
              ),
            );
          }
          if (loaded.length >= widget.totalQuestions) break;
        }
      } catch (_) {
        // Fall back gracefully
      }

      // 2. Supplement from curriculum question bank to ensure full quota
      if (loaded.length < widget.totalQuestions) {
        final defaults = _getDefaultCurriculumQuestions(widget.subject, widget.topic);
        for (final q in defaults) {
          if (!loaded.any((existing) => existing.question == q.question)) {
            loaded.add(q);
          }
          if (loaded.length >= widget.totalQuestions) break;
        }
      }

      if (mounted) {
        setState(() {
          _questions = loaded.take(widget.totalQuestions).toList();
          _secondsRemaining = (_questions.length * 60).clamp(180, 600); // 1 min per question
          _isLoadingQuestions = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _questions = _getDefaultCurriculumQuestions(widget.subject, widget.topic).take(widget.totalQuestions).toList();
          _isLoadingQuestions = false;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    if (!widget.enableTimer) return;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _submitChallenge(isTimeUp: true);
      }
    });
  }

  List<ChallengeQuestion> _getDefaultCurriculumQuestions(String subject, String? topic) {
    return const [
      ChallengeQuestion(
        id: 'q_math_01',
        subject: 'Mathematics',
        topic: 'Algebra & Linear Equations',
        question: 'Solve for x in the equation: 3x - 7 = 14.',
        options: ['x = 5', 'x = 7', 'x = 9', 'x = 3'],
        correctAnswer: 'x = 7',
        explanation: 'Add 7 to both sides: 3x = 21. Divide by 3: x = 7.',
      ),
      ChallengeQuestion(
        id: 'q_sci_01',
        subject: 'Science',
        topic: 'Cell Biology & Energy',
        question: 'Which organelle is known as the powerhouse of the cell?',
        options: ['Ribosome', 'Mitochondria', 'Endoplasmic Reticulum', 'Golgi Apparatus'],
        correctAnswer: 'Mitochondria',
        explanation: 'Mitochondria generate most of the chemical energy needed by the cell (ATP).',
      ),
      ChallengeQuestion(
        id: 'q_eng_01',
        subject: 'English',
        topic: 'Grammar & Voice',
        question: 'Identify the passive voice sentence:',
        options: [
          'The chef cooked a delicious meal.',
          'A delicious meal was cooked by the chef.',
          'The children played in the garden.',
          'She will write a letter tomorrow.'
        ],
        correctAnswer: 'A delicious meal was cooked by the chef.',
        explanation: 'In passive voice, the subject receives the action ("was cooked by").',
      ),
      ChallengeQuestion(
        id: 'q_soc_01',
        subject: 'Social Studies',
        topic: 'Indian Constitution',
        question: 'Who is recognized as the chief architect of the Constitution of India?',
        options: [
          'Mahatma Gandhi',
          'Dr. B. R. Ambedkar',
          'Jawaharlal Nehru',
          'Sardar Vallabhbhai Patel'
        ],
        correctAnswer: 'Dr. B. R. Ambedkar',
        explanation: 'Dr. B. R. Ambedkar served as the Chairman of the Drafting Committee of the Constitution.',
      ),
      ChallengeQuestion(
        id: 'q_math_02',
        subject: 'Mathematics',
        topic: 'Geometry & Mensuration',
        question: 'What is the area of a right-angled triangle with base 8 cm and height 5 cm?',
        options: ['40 cm²', '20 cm²', '13 cm²', '26 cm²'],
        correctAnswer: '20 cm²',
        explanation: 'Area of triangle = 1/2 × base × height = 1/2 × 8 × 5 = 20 cm².',
      ),
      ChallengeQuestion(
        id: 'q_sci_02',
        subject: 'Science',
        topic: 'Photosynthesis',
        question: 'What gas is released by green plants during the process of photosynthesis?',
        options: ['Carbon Dioxide', 'Oxygen', 'Nitrogen', 'Hydrogen'],
        correctAnswer: 'Oxygen',
        explanation: 'Plants use sunlight, water, and CO2 to produce glucose and release Oxygen (O2).',
      ),
    ];
  }

  Future<void> _submitChallenge({bool isTimeUp = false}) async {
    _countdownTimer?.cancel();

    if (_isSubmitted) return;

    setState(() {
      _isSubmitted = true;
      _isSavingResults = true;
    });

    // 1. Calculate Score
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final userAns = _selectedAnswers[i];
      if (userAns != null && userAns.trim() == q.correctAnswer.trim()) {
        correct++;
      }
    }

    final total = _questions.length;
    final scorePct = total > 0 ? (correct / total) : 0.0;

    // 2. Compute XP Reward: Full reward if score >= 80%, proportional if lower (minimum 15 XP)
    int xp = 15;
    if (scorePct >= 0.8) {
      xp = widget.xpReward;
    } else if (scorePct >= 0.5) {
      xp = (widget.xpReward * 0.7).round();
    } else if (correct > 0) {
      xp = (widget.xpReward * 0.4).round();
    }

    setState(() {
      _correctCount = correct;
      _earnedXp = xp;
    });

    try {
      final schoolId = widget.schoolId ?? 'school_ap_01';

      // 3. Award XP in Firestore with audit trail
      await _gamificationService.addXP(
        widget.studentId,
        xp,
        reason: 'Practice Challenge: ${widget.challengeTitle} ($correct/$total correct)',
        type: 'earn',
      );

      // 4. Save question attempts to Firestore
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final userAns = _selectedAnswers[i] ?? 'skipped';
        final isCorrect = userAns.trim() == q.correctAnswer.trim();

        try {
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('ai_generated_tasks')
              .doc(q.id)
              .set({
            'studentAnswers.${widget.studentId}': {
              'selectedOption': userAns,
              'isCorrect': isCorrect,
              'answeredAt': Timestamp.now(),
            },
            if (isCorrect) 'completedBy': FieldValue.arrayUnion([widget.studentId]),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // 5. Update Skill Intelligence radar profile in real-time
      try {
        await SkillIntelligenceService().calculateStudentSkillProfile(
          widget.studentId,
          schoolId,
        );
      } catch (_) {}

      // 6. Complete linked challenge if provided
      if (widget.challengeId != null && widget.challengeId!.isNotEmpty) {
        try {
          await _challengeService.completeChallenge(widget.challengeId!, widget.studentId);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error finalizing challenge results: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingResults = false);
      }
    }
  }

  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 20,
        vertical: isCompact ? 12 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: (media.size.height - (isCompact ? 24 : 48)).clamp(360.0, 820.0),
        ),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkBg,
          borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
          border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: (_isLoadingQuestions || _isSavingResults)
            ? _buildLoadingState(_isSavingResults ? 'Evaluating & Saving Results...' : 'Preparing Challenge...')
            : _isSubmitted
                ? _buildResultsView(isCompact)
                : _buildActiveQuizView(isCompact),
      ),
    );
  }

  Widget _buildLoadingState([String? message]) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: EduStreakTheme.primaryViolet),
          ),
          const SizedBox(height: 20),
          Text(
            message ?? 'Preparing Challenge...',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Loading questions aligned to your class and curriculum...',
            style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuizView(bool isCompact) {
    final q = _questions[_currentIndex];
    final selectedOption = _selectedAnswers[_currentIndex];
    final isTimerLow = _secondsRemaining < 60;

    return Column(
      children: [
        // 1. Header with title, subject, timer & close
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 20,
            isCompact ? 12 : 18,
            isCompact ? 12 : 20,
            isCompact ? 10 : 14,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 8),
                decoration: BoxDecoration(
                  color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: EduStreakTheme.primaryViolet,
                  size: isCompact ? 18 : 20,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.challengeTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${q.subject} • ${q.topic}',
                      style: TextStyle(
                        color: EduStreakTheme.studentDarkTextMuted,
                        fontSize: isCompact ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Countdown Timer Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 6 : 10,
                  vertical: isCompact ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: isTimerLow
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : EduStreakTheme.studentDarkCardSub,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTimerLow ? Colors.redAccent : EduStreakTheme.studentDarkBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: isCompact ? 12 : 14,
                      color: isTimerLow ? Colors.redAccent : const Color(0xFFC4B5FD),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimer(_secondsRemaining),
                      style: TextStyle(
                        color: isTimerLow ? Colors.redAccent : Colors.white,
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.close_rounded, color: EduStreakTheme.studentDarkTextMuted),
                tooltip: 'Exit Challenge',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: EduStreakTheme.studentDarkCard,
                      title: const Text('Exit Challenge?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text(
                        'Your progress will not be saved if you exit now.',
                        style: TextStyle(color: EduStreakTheme.studentDarkTextMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Keep Practicing', style: TextStyle(color: EduStreakTheme.primaryViolet)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Exit', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),

        // 2. Question Stepper Dots Bar
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: isCompact ? 8 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: TextStyle(
                        color: const Color(0xFFC4B5FD),
                        fontSize: isCompact ? 12 : 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedAnswers.length}/${_questions.length} Answered',
                    style: TextStyle(
                      color: EduStreakTheme.studentDarkTextMuted,
                      fontSize: isCompact ? 11 : 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  minHeight: 6,
                  backgroundColor: EduStreakTheme.studentDarkCardSub,
                  valueColor: const AlwaysStoppedAnimation<Color>(EduStreakTheme.primaryViolet),
                ),
              ),
            ],
          ),
        ),

        // 3. Question & Options (Scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 20,
              6,
              isCompact ? 12 : 20,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isCompact ? 14 : 20),
                  decoration: BoxDecoration(
                    color: EduStreakTheme.studentDarkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: EduStreakTheme.studentDarkBorder),
                  ),
                  child: Text(
                    q.question,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 18),

                // Options List
                ...List.generate(q.options.length, (optIndex) {
                  final optionText = q.options[optIndex];
                  final isSelected = selectedOption == optionText;
                  final optionLetter = String.fromCharCode(65 + optIndex);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      key: Key('challenge_option_$optIndex'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _selectedAnswers[_currentIndex] = optionText;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: isCompact ? 10 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? EduStreakTheme.primaryViolet.withValues(alpha: 0.18)
                              : EduStreakTheme.studentDarkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? EduStreakTheme.primaryViolet
                                : EduStreakTheme.studentDarkBorder,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isCompact ? 28 : 32,
                              height: isCompact ? 28 : 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? EduStreakTheme.primaryViolet
                                    : EduStreakTheme.studentDarkCardSub,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 12 : 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isCompact ? 10 : 14),
                            Expanded(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                                  fontSize: isCompact ? 13.5 : 14.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // 4. Bottom Controls: Prev, Next, Submit
        const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 20,
            vertical: isCompact ? 10 : 14,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  key: const Key('challenge_prev_button'),
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(
                    isCompact ? 'Prev' : 'Previous',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white24,
                    side: BorderSide(
                      color: _currentIndex > 0
                          ? EduStreakTheme.studentDarkBorder
                          : EduStreakTheme.studentDarkBorder.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 14,
                      vertical: isCompact ? 10 : 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                flex: 1,
                child: _currentIndex < _questions.length - 1
                    ? ElevatedButton.icon(
                        key: const Key('challenge_next_button'),
                        onPressed: () => setState(() => _currentIndex++),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7950FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 10 : 20,
                            vertical: isCompact ? 10 : 12,
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        key: const Key('challenge_submit_button'),
                        onPressed: () => _submitChallenge(),
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: Text(
                          isCompact ? 'Submit' : 'Submit Challenge',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 10 : 20,
                            vertical: isCompact ? 10 : 12,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView([bool isCompact = false]) {
    final total = _questions.length;
    final pct = total > 0 ? ((_correctCount / total) * 100).toInt() : 0;
    final isPassed = pct >= 60;

    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 20,
            isCompact ? 14 : 20,
            isCompact ? 12 : 20,
            isCompact ? 10 : 14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isPassed ? '🎉 Challenge Completed!' : '👍 Good Effort!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 16 : 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),

        // Score Hero Card
        Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPassed
                    ? [const Color(0xFF152A38), const Color(0xFF0F1E28)]
                    : [const Color(0xFF281C38), const Color(0xFF1B1428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPassed ? const Color(0xFF10B981) : EduStreakTheme.primaryViolet,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Text(isPassed ? '🏆' : '🎯', style: TextStyle(fontSize: isCompact ? 36 : 48)),
                SizedBox(width: isCompact ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: $_correctCount / $total ($pct%)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 18 : 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '+$_earnedXp XP Earned & Logged',
                              style: TextStyle(
                                color: const Color(0xFFFBBF24),
                                fontSize: isCompact ? 12 : 14,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Review List
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
          child: const Row(
            children: [
              Text(
                'Question Breakdown & Solutions:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 20,
              0,
              isCompact ? 12 : 20,
              20,
            ),
            itemCount: _questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final q = _questions[idx];
              final userAns = _selectedAnswers[idx];
              final isCorrect = userAns != null && userAns.trim() == q.correctAnswer.trim();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCorrect
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : Colors.redAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Q${idx + 1}: ${q.question}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Answer: ${userAns ?? "Skipped"}',
                      style: TextStyle(
                        color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isCorrect)
                      Text(
                        'Correct: ${q.correctAnswer}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.studentDarkCardSub,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '💡 Explanation: ${q.explanation}',
                        style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Footer button
        const Divider(height: 1, color: EduStreakTheme.studentDarkBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduStreakTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Return to Practice Arena', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }
}
