import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/ai_task_model.dart';
import '../../services/ai_task_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/edustreak_illustrations.dart';
import 'widgets/practice_challenge_session_dialog.dart';

class AiPracticeTab extends StatefulWidget {
  final String studentId;
  final String classId;
  final String? schoolId;

  const AiPracticeTab({
    super.key,
    required this.studentId,
    required this.classId,
    this.schoolId,
  });

  @override
  State<AiPracticeTab> createState() => _AiPracticeTabState();
}

class _AiPracticeTabState extends State<AiPracticeTab> {
  final AiTaskService _aiTaskService = AiTaskService();
  bool _isGenerating = false;
  String? _focusSubject;
  String? _focusTopic;
  String? _focusReason;

  @override
  void initState() {
    super.initState();
    _loadWeakTopicFocus();
  }

  Future<void> _loadWeakTopicFocus() async {
    try {
      final diagnosis = await _aiTaskService.detectWeakTopic(widget.studentId);
      if (mounted) {
        setState(() {
          _focusSubject = diagnosis['subject'];
          _focusTopic = diagnosis['topic'];
          _focusReason = diagnosis['reason'];
        });
      }
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> _requestNewAiTask(String studentName) async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final user = Provider.of<UserProvider>(context, listen: false).currentUser;
      final effectiveSchoolId = widget.schoolId ?? user?.schoolId ?? 'default_school';
      final result = await _aiTaskService.generatePersonalizedTaskForStudent(
        studentId: widget.studentId,
        studentName: studentName,
        classId: widget.classId,
        schoolId: effectiveSchoolId,
        preferredSubject: _focusSubject,
        preferredTopic: _focusTopic,
      );

      if (!mounted) return;

      if (result.success) {
        if (result.isCached) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ ${result.message}'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎯 New question generated! Sent to your teacher for review.'),
              backgroundColor: EduStreakTheme.primaryViolet,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't generate right now, try later."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final studentName = (userProvider.currentUser?.name.isNotEmpty == true)
        ? userProvider.currentUser!.name
        : 'Student';

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadWeakTopicFocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Page Header (Gamepad + Practice Arena + Subtitle)
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. Top Row: Daily Practice Challenge Hero + Practice Stats Card
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isDesktop = width >= 860;

                  final heroCard = _buildDailyChallengeHero();
                  final statsCard = _buildPracticeStatsCard();

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: heroCard),
                        const SizedBox(width: 16),
                        SizedBox(width: 260, child: statsCard),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        heroCard,
                        const SizedBox(height: 16),
                        statsCard,
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // 3. Section: "Practice by Subject"
              const Text(
                'Practice by Subject',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              _buildPracticeBySubjectGrid(),

              const SizedBox(height: 26),

              // 4. Adaptive Learning Focus Banner (Interactive AI Generator)
              _buildAdaptiveGeneratorBanner(studentName),

              const SizedBox(height: 24),

              // 5. Approved Practice Tasks Section
              _buildApprovedTasksSection(),
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
          child: const Icon(Icons.sports_esports_rounded, color: EduStreakTheme.primaryViolet, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Practice Arena',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('🎯', style: TextStyle(fontSize: 18)),
                ],
              ),
              SizedBox(height: 2),
              Text(
                'Sharpen your skills with topic-wise practice, MCQs and challenges!',
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

  // ─── HERO CARD: DAILY PRACTICE CHALLENGE (MATCHES APPROVED REFERENCE) ─────
  Widget _buildDailyChallengeHero() {
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
          final isNarrow = constraints.maxWidth < 520;
          return Row(
            children: [
              // Mascot on Left (Akash smiling/waving)
              const AkashStudentAvatar(size: 68),
              const SizedBox(width: 16),

              // Middle Challenge Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Daily Challenge Tag
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7950FF).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.military_tech_rounded, size: 14, color: Color(0xFFC4B5FD)),
                              SizedBox(width: 4),
                              Text(
                                'Daily Practice Challenge',
                                style: TextStyle(
                                  color: Color(0xFFC4B5FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mixed Quiz • 10 MCQs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Maths • Science • English',
                      style: TextStyle(
                        color: EduStreakTheme.studentDarkTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Earn 50 XP',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Open quick challenge dialog
                        _showQuickDailyChallenge();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7950FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        elevation: 4,
                        shadowColor: const Color(0xFF7950FF).withValues(alpha: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Start Challenge'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3D Golden Trophy on Illuminated Pedestal on Right
              if (!isNarrow) ...[
                const SizedBox(width: 14),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFF7950FF), Colors.transparent],
                      stops: [0.15, 0.5, 1.0],
                    ),
                  ),
                  child: const Center(
                    child: Text('🏆✨', style: TextStyle(fontSize: 38)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── CARD: PRACTICE STATS (RIGHT TOP CARD) ────────────────────────────────
  Widget _buildPracticeStatsCard() {
    final stats = [
      {'val': '432', 'label': 'MCQs Attempted', 'color': const Color(0xFF7950FF), 'icon': Icons.quiz_rounded},
      {'val': '86%', 'label': 'Average Accuracy', 'color': const Color(0xFF10B981), 'icon': Icons.track_changes_rounded},
      {'val': '12', 'label': 'Practice Streak', 'color': const Color(0xFFFF6B35), 'icon': Icons.local_fire_department_rounded},
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.adjust_rounded, color: Color(0xFFC4B5FD), size: 18),
              SizedBox(width: 8),
              Text(
                'Practice Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.map((s) {
            final color = s['color'] as Color;
            final icon = s['icon'] as IconData;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['val'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          s['label'] as String,
                          style: const TextStyle(
                            color: EduStreakTheme.studentDarkTextMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── PRACTICE BY SUBJECT 4-CARD GRID (MATCHES APPROVED REFERENCE) ────────
  Widget _buildPracticeBySubjectGrid() {
    final subjects = [
      {'name': 'Maths', 'mcqs': '1,240 MCQs', 'percent': 76, 'color': const Color(0xFF00D4FF), 'icon': Icons.calculate_rounded},
      {'name': 'Science', 'mcqs': '980 MCQs', 'percent': 88, 'color': const Color(0xFF10B981), 'icon': Icons.science_rounded},
      {'name': 'English', 'mcqs': '760 MCQs', 'percent': 82, 'color': const Color(0xFFEC4899), 'icon': Icons.menu_book_rounded},
      {'name': 'Social', 'mcqs': '620 MCQs', 'percent': 71, 'color': const Color(0xFFA855F7), 'icon': Icons.public_rounded},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = width >= 900 ? 4 : (width >= 550 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final s = subjects[index];
            final name = s['name'] as String;
            final mcqs = s['mcqs'] as String;
            final percent = s['percent'] as int;
            final color = s['color'] as Color;
            final icon = s['icon'] as IconData;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: EduStreakTheme.studentDarkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                mcqs,
                                style: const TextStyle(
                                  color: EduStreakTheme.studentDarkTextMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100.0,
                      minHeight: 6,
                      backgroundColor: EduStreakTheme.studentDarkCardSub,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── ADAPTIVE AI PRACTICE BANNER ─────────────────────────────────────────
  Widget _buildAdaptiveGeneratorBanner(String studentName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 20),
              SizedBox(width: 8),
              Text(
                'Adaptive AI Practice Generator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _focusTopic != null
                ? 'Identified Weak Area: $_focusSubject — $_focusTopic'
                : 'Analyzing your recent performance to tailor personalized questions...',
            style: const TextStyle(
              color: EduStreakTheme.studentDarkHighlight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_focusReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Diagnostic insight: $_focusReason',
              style: const TextStyle(
                color: EduStreakTheme.studentDarkTextMuted,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : () => _requestNewAiTask(studentName),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24)),
              label: Text(
                _isGenerating ? 'Analyzing & Generating...' : 'Generate New Practice Question',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7950FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── APPROVED PRACTICE TASKS STREAM ──────────────────────────────────────
  Widget _buildApprovedTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Approved Practice Tasks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '+15 XP each',
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AiTaskModel>>(
          stream: _aiTaskService.getApprovedPracticeTasks(
            schoolId: widget.schoolId ??
                (Provider.of<UserProvider>(context, listen: false).currentUser?.schoolId ?? 'default_school'),
            studentId: widget.studentId,
            classId: widget.classId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                ),
              );
            }

            final tasks = snapshot.data ?? [];
            if (tasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: EduStreakTheme.studentDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EduStreakTheme.studentDarkBorder),
                ),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.quiz_outlined, size: 48, color: EduStreakTheme.studentDarkTextMuted),
                      SizedBox(height: 10),
                      Text(
                        'No practice questions ready yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap "Generate New Practice Question" above to request personalized MCQs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: EduStreakTheme.studentDarkTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isCompleted = task.completedBy.contains(widget.studentId);
                return _buildPracticeCard(task, isCompleted);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPracticeCard(AiTaskModel task, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7950FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${task.subject} • ${task.topic}',
                  style: const TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Completed (+15 XP)',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openQuizDialog(task, isCompleted),
              icon: Icon(
                isCompleted ? Icons.visibility_rounded : Icons.play_arrow_rounded,
                size: 16,
              ),
              label: Text(isCompleted ? 'Review Solution' : 'Start Practice Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? EduStreakTheme.studentDarkCardSub : const Color(0xFF7950FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickDailyChallenge() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    final studentName = user?.name.isNotEmpty == true ? user!.name : 'Student';

    PracticeChallengeSessionDialog.start(
      context,
      studentId: widget.studentId,
      studentName: studentName,
      classId: widget.classId,
      schoolId: widget.schoolId,
      challengeTitle: 'Daily Practice Challenge',
      subject: 'Mixed Quiz',
      totalQuestions: 5,
      xpReward: 50,
    );
  }

  void _openQuizDialog(AiTaskModel task, bool isAlreadyCompleted) {
    String? selectedOption;
    bool submitted = isAlreadyCompleted;
    bool? isCorrect;
    String explanation = task.explanation;
    int xpEarned = 0;

    final previousSubmission = task.studentAnswers[widget.studentId] as Map<String, dynamic>?;
    if (previousSubmission != null) {
      selectedOption = previousSubmission['selectedOption']?.toString();
      isCorrect = previousSubmission['isCorrect'] == true;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: EduStreakTheme.studentDarkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: EduStreakTheme.studentDarkBorder),
              ),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${task.subject}: ${task.topic}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.question,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 14),

                    // Options
                    ...task.options.map((opt) {
                      final isSelected = selectedOption == opt;
                      Color tileColor = EduStreakTheme.studentDarkCardSub;
                      Color borderColor = EduStreakTheme.studentDarkBorder;

                      if (submitted) {
                        final isThisCorrect = opt.trim() == task.correctAnswer.trim();
                        if (isThisCorrect) {
                          tileColor = const Color(0xFF10B981).withValues(alpha: 0.2);
                          borderColor = const Color(0xFF10B981);
                        } else if (isSelected && !isThisCorrect) {
                          tileColor = const Color(0xFFEF4444).withValues(alpha: 0.2);
                          borderColor = const Color(0xFFEF4444);
                        }
                      } else if (isSelected) {
                        tileColor = const Color(0xFF7950FF).withValues(alpha: 0.25);
                        borderColor = const Color(0xFF7950FF);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
                        ),
                        child: RadioListTile<String>(
                          value: opt,
                          groupValue: selectedOption,
                          activeColor: const Color(0xFF7950FF),
                          dense: true,
                          title: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onChanged: submitted
                              ? null
                              : (val) {
                                  setDialogState(() => selectedOption = val);
                                },
                        ),
                      );
                    }),

                    // Result & Explanation
                    if (submitted) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isCorrect == true)
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isCorrect == true) ? const Color(0xFF10B981) : Colors.orange,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  (isCorrect == true) ? Icons.check_circle : Icons.info,
                                  color: (isCorrect == true) ? const Color(0xFF10B981) : Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (isCorrect == true) ? 'Great Job! Correct Answer' : 'Keep Trying!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (isCorrect == true) ? const Color(0xFF10B981) : Colors.orange,
                                  ),
                                ),
                                if (xpEarned > 0) ...[
                                  const Spacer(),
                                  Text(
                                    '+$xpEarned XP',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                                  ),
                                ],
                              ],
                            ),
                            if (explanation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                explanation,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(submitted ? 'Close' : 'Cancel', style: const TextStyle(color: EduStreakTheme.studentDarkTextMuted)),
                ),
                if (!submitted)
                  ElevatedButton(
                    onPressed: selectedOption == null
                        ? null
                        : () async {
                            final result = await _aiTaskService.submitStudentAnswer(
                              schoolId: task.schoolId,
                              taskId: task.id,
                              studentId: widget.studentId,
                              selectedOption: selectedOption!,
                            );

                            setDialogState(() {
                              submitted = true;
                              isCorrect = result['isCorrect'] == true;
                              explanation = result['explanation']?.toString() ?? task.explanation;
                              xpEarned = (result['xpEarned'] as num?)?.toInt() ?? 0;
                            });

                            if (mounted && (result['xpEarned'] as int? ?? 0) > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🎉 Correct! Earned +${result["xpEarned"]} XP!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7950FF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit Answer'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
