import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/assessment_model.dart';
import '../../services/assessment_service.dart';

class AssessmentTakingDialog extends StatefulWidget {
  final AssessmentModel assessment;
  final String studentId;
  final String studentName;
  final bool isReviewMode;

  const AssessmentTakingDialog({
    super.key,
    required this.assessment,
    required this.studentId,
    required this.studentName,
    this.isReviewMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required AssessmentModel assessment,
    required String studentId,
    required String studentName,
    bool isReviewMode = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssessmentTakingDialog(
        assessment: assessment,
        studentId: studentId,
        studentName: studentName,
        isReviewMode: isReviewMode,
      ),
    );
  }

  @override
  State<AssessmentTakingDialog> createState() => _AssessmentTakingDialogState();
}

class _AssessmentTakingDialogState extends State<AssessmentTakingDialog> {
  final AssessmentService _assessmentService = AssessmentService();

  int _currentIndex = 0;
  final Map<String, dynamic> _answers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  Map<String, dynamic>? _submissionResult;
  bool _showingResult = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate answers if review mode or existing answers exist
    if (widget.isReviewMode || widget.assessment.studentAnswers.containsKey(widget.studentId)) {
      final existing = widget.assessment.studentAnswers[widget.studentId];
      if (existing != null) {
        _answers.addAll(existing);
      }
    }

    if (!widget.isReviewMode) {
      _remainingSeconds = widget.assessment.durationMinutes > 0
          ? widget.assessment.durationMinutes * 60
          : 45 * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _autoSubmitDueToTime();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _autoSubmitDueToTime() {
    if (_showingResult || _isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Time is up! Submitting your assessment...'),
        backgroundColor: Colors.amber,
      ),
    );
    _submitAssessment();
  }

  String _formatTimer(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submitAssessment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final result = await _assessmentService.submitStudentAssessment(
        assessmentId: widget.assessment.id,
        studentId: widget.studentId,
        answers: _answers,
        studentName: widget.studentName,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionResult = result;
          _showingResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting assessment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmSubmit() {
    final answeredCount = _answers.keys.where((k) => _answers[k]?.toString().trim().isNotEmpty == true).length;
    final totalCount = widget.assessment.questions.length;
    final unanswered = totalCount - answeredCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141A42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF6C57FF), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: Color(0xFF06B6D4)),
            SizedBox(width: 10),
            Text('Submit Assessment?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have answered $answeredCount of $totalCount questions.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (unanswered > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Warning: $unanswered question${unanswered > 1 ? "s are" : " is"} unanswered!',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Once submitted, your objective answers will be evaluated immediately.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Test', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitAssessment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Yes, Submit Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.assessment.questions;
    final isReview = widget.isReviewMode || _showingResult;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 900,
        height: 720,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F2D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C57FF).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C57FF).withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── Top Bar ──
              _buildTopBar(isReview),

              // ── Main Body ──
              Expanded(
                child: _showingResult
                    ? _buildResultCelebrationView()
                    : (questions.isEmpty
                        ? _buildEmptyQuestionsView()
                        : _buildQuestionRunner(questions, isReview)),
              ),

              // ── Bottom Navigation / Actions ──
              if (!_showingResult && questions.isNotEmpty)
                _buildBottomBar(questions, isReview),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isReview) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C57FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.quiz_rounded, color: Color(0xFFA855F7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.assessment.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.assessment.subject} • ${widget.assessment.totalMarks} Marks • ${widget.assessment.questions.length} Questions',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Timer if active
          if (!isReview)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300
                    ? Colors.red.withOpacity(0.2)
                    : const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _remainingSeconds < 300 ? Colors.redAccent : const Color(0xFF06B6D4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: _remainingSeconds < 300 ? Colors.redAccent : const Color(0xFF06B6D4),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTimer(_remainingSeconds),
                    style: TextStyle(
                      color: _remainingSeconds < 300 ? Colors.redAccent : const Color(0xFF06B6D4),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 12),

          // Close button
          IconButton(
            onPressed: () {
              if (!isReview && !_answers.isEmpty) {
                _confirmExit();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141A42),
        title: const Text('Exit Test?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your progress will not be submitted until you complete the assessment. Are you sure you want to leave?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestionsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.assignment_late_outlined, color: Colors.white38, size: 56),
          SizedBox(height: 16),
          Text(
            'No questions configured for this assessment.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionRunner(List<AssessmentQuestion> questions, bool isReview) {
    final currentQ = questions[_currentIndex];
    final selectedAns = _answers[currentQ.id]?.toString() ?? '';
    final isMcq = currentQ.type == 'mcq' || currentQ.options.isNotEmpty;

    // Review metrics for this question
    final bool isCorrect = selectedAns.isNotEmpty &&
        (selectedAns.toLowerCase() == currentQ.correctAnswer.toLowerCase() ||
            (currentQ.options.containsKey(selectedAns) &&
                currentQ.options[selectedAns]?.toLowerCase() == currentQ.correctAnswer.toLowerCase()));

    return Row(
      children: [
        // ── Question Jump Sidebar (Desktop/Tablet) ──
        Container(
          width: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1538),
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'QUESTIONS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, idx) {
                    final q = questions[idx];
                    final isCurrent = idx == _currentIndex;
                    final isAnswered = _answers[q.id]?.toString().trim().isNotEmpty == true;

                    Color tileColor;
                    Color borderColor;

                    if (isReview) {
                      final ans = _answers[q.id]?.toString() ?? '';
                      final correct = ans.isNotEmpty &&
                          (ans.toLowerCase() == q.correctAnswer.toLowerCase() ||
                              (q.options.containsKey(ans) &&
                                  q.options[ans]?.toLowerCase() == q.correctAnswer.toLowerCase()));
                      if (ans.isEmpty) {
                        tileColor = Colors.white10;
                        borderColor = Colors.white24;
                      } else if (correct) {
                        tileColor = const Color(0xFF10B981).withOpacity(0.2);
                        borderColor = const Color(0xFF10B981);
                      } else {
                        tileColor = Colors.red.withOpacity(0.2);
                        borderColor = Colors.redAccent;
                      }
                    } else {
                      if (isCurrent) {
                        tileColor = const Color(0xFF6C57FF).withOpacity(0.3);
                        borderColor = const Color(0xFF6C57FF);
                      } else if (isAnswered) {
                        tileColor = const Color(0xFF10B981).withOpacity(0.15);
                        borderColor = const Color(0xFF10B981).withOpacity(0.5);
                      } else {
                        tileColor = Colors.white.withOpacity(0.03);
                        borderColor = Colors.white.withOpacity(0.12);
                      }
                    }

                    return InkWell(
                      onTap: () => setState(() => _currentIndex = idx),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white70,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
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

        // ── Question Detail & Answering Area ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C57FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'QUESTION ${_currentIndex + 1} OF ${questions.length}',
                        style: const TextStyle(
                          color: Color(0xFFA855F7),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${currentQ.marks} Marks',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Question Statement
                Text(
                  currentQ.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // If Review Mode, show correctness badge
                if (isReview) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'Correct! Full marks awarded (+${currentQ.marks}).'
                                : 'Incorrect. Correct Answer: ${currentQ.correctAnswer}',
                            style: TextStyle(
                              color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Options or Text Field
                if (isMcq) ...[
                  ...currentQ.options.entries.map((entry) {
                    final optionKey = entry.key; // e.g. 'A'
                    final optionText = entry.value; // e.g. 'x = 5'
                    final isSelected = selectedAns == optionKey || selectedAns == optionText;
                    final isOptionCorrect = isReview &&
                        (currentQ.correctAnswer.toLowerCase() == optionKey.toLowerCase() ||
                            currentQ.correctAnswer.toLowerCase() == optionText.toLowerCase());

                    Color cardBg;
                    Color cardBorder;

                    if (isReview) {
                      if (isOptionCorrect) {
                        cardBg = const Color(0xFF10B981).withOpacity(0.2);
                        cardBorder = const Color(0xFF10B981);
                      } else if (isSelected && !isOptionCorrect) {
                        cardBg = Colors.red.withOpacity(0.2);
                        cardBorder = Colors.redAccent;
                      } else {
                        cardBg = Colors.white.withOpacity(0.02);
                        cardBorder = Colors.white.withOpacity(0.08);
                      }
                    } else {
                      if (isSelected) {
                        cardBg = const Color(0xFF6C57FF).withOpacity(0.25);
                        cardBorder = const Color(0xFF6C57FF);
                      } else {
                        cardBg = Colors.white.withOpacity(0.03);
                        cardBorder = Colors.white.withOpacity(0.1);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isReview
                            ? null
                            : () {
                                setState(() {
                                  _answers[currentQ.id] = optionKey;
                                });
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder, width: isSelected ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? (isReview
                                          ? (isOptionCorrect ? const Color(0xFF10B981) : Colors.redAccent)
                                          : const Color(0xFF6C57FF))
                                      : Colors.white.withOpacity(0.06),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  optionKey,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isReview && isOptionCorrect)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ] else ...[
                  // Subjective / Short Answer
                  TextFormField(
                    initialValue: selectedAns,
                    enabled: !isReview,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your explanation or answer here...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C57FF)),
                      ),
                    ),
                    onChanged: (val) {
                      _answers[currentQ.id] = val;
                    },
                  ),
                ],

                // Explanation if available in review
                if (isReview && currentQ.explanation.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF06B6D4), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Concept Explanation',
                              style: TextStyle(
                                color: Color(0xFF06B6D4),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentQ.explanation,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(List<AssessmentQuestion> questions, bool isReview) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          OutlinedButton.icon(
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),

          // Progress indicator in middle
          Text(
            '${_currentIndex + 1} of ${questions.length}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),

          // Next or Submit button
          if (_currentIndex < questions.length - 1)
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentIndex++),
              icon: const Text('Next'),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C57FF),
                foregroundColor: Colors.white,
              ),
            )
          else if (!isReview)
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _confirmSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C57FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done Reviewing'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCelebrationView() {
    final score = (_submissionResult?['score'] as num?)?.toDouble() ?? 0.0;
    final total = (_submissionResult?['totalMarks'] as num?)?.toInt() ?? widget.assessment.totalMarks;
    final xp = (_submissionResult?['xpEarned'] as num?)?.toInt() ?? 100;
    final pct = total > 0 ? ((score / total) * 100).round() : 0;
    final isAllObj = _submissionResult?['isAllObjective'] ?? true;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / Star Badge
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF6C57FF), Color(0xFF141A42)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C57FF).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 50),
            ),

            const SizedBox(height: 20),

            const Text(
              'Assessment Completed!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isAllObj
                  ? 'All objective answers evaluated instantly.'
                  : 'Submitted successfully! Awaiting teacher review for descriptive answers.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Score Cards Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScorePill('Score', '${score.toStringAsFixed(0)} / $total', const Color(0xFF10B981)),
                const SizedBox(width: 16),
                _buildScorePill('Percentage', '$pct%', const Color(0xFF06B6D4)),
                const SizedBox(width: 16),
                _buildScorePill('XP Earned', '+$xp XP', Colors.amber),
              ],
            ),

            const SizedBox(height: 36),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showingResult = false;
                      _currentIndex = 0;
                    });
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Review Answers & Explanations'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF6C57FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Return to Assessments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C57FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
