import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/assessment_model.dart';
import '../../providers/user_provider.dart';
import '../../services/assessment_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';
import 'assessment_taking_dialog.dart';

class StudentAssessmentsScreen extends StatefulWidget {
  const StudentAssessmentsScreen({super.key});

  @override
  State<StudentAssessmentsScreen> createState() => _StudentAssessmentsScreenState();
}

class _StudentAssessmentsScreenState extends State<StudentAssessmentsScreen> {
  final AssessmentService _assessmentService = AssessmentService();
  String _selectedFilter = 'All'; // 'All', 'Available', 'Completed', 'Upcoming'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
    }

    return Container(
      color: EduStreakTheme.studentDarkBg,
      child: StreamBuilder<List<AssessmentModel>>(
        stream: _assessmentService.getAssessmentsForStudent(
          studentId: currentUser.id,
          classId: currentUser.classId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
          }

          final allAssessments = snapshot.data ?? [];

          // Compute KPI Metrics
          int available = 0;
          int completed = 0;
          double totalScorePct = 0.0;
          int scoredCount = 0;

          for (final a in allAssessments) {
            final hasSub = a.submissions.containsKey(currentUser.id);
            if (hasSub) {
              completed++;
              final score = a.scores[currentUser.id];
              if (score != null && a.totalMarks > 0) {
                totalScorePct += (score / a.totalMarks) * 100.0;
                scoredCount++;
              }
            } else {
              available++;
            }
          }

          final avgScore = scoredCount > 0 ? (totalScorePct / scoredCount).round() : 0;
          final totalXp = completed * 100;

          // Filter assessments
          final filtered = allAssessments.where((a) {
            final hasSub = a.submissions.containsKey(currentUser.id);
            final isUpcoming = a.scheduledDate.isAfter(DateTime.now());

            if (_selectedFilter == 'Available' && hasSub) return false;
            if (_selectedFilter == 'Completed' && !hasSub) return false;
            if (_selectedFilter == 'Upcoming' && !isUpcoming) return false;

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final tMatch = a.title.toLowerCase().contains(q);
              final sMatch = a.subject.toLowerCase().contains(q);
              final cMatch = a.chapter.toLowerCase().contains(q);
              return tMatch || sMatch || cMatch;
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                _buildHeader(currentUser.classId),

                const SizedBox(height: 20),

                // 2. Metrics Cards
                _buildMetricCards(
                  available: available,
                  completed: completed,
                  avgScore: avgScore,
                  totalXp: totalXp,
                ),

                const SizedBox(height: 24),

                // 3. Search and Filters
                _buildSearchAndFilters(),

                const SizedBox(height: 20),

                // 4. Assessments List
                if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  ...filtered.map((a) => _buildAssessmentCard(a, currentUser.id, currentUser.name)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String? classId) {
    final displayClass = ClassNameHelper.cleanFormattedName(classId ?? '');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C57FF).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Color(0xFFA855F7), size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Assessments & Tests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Formal evaluations, quizzes, and unit exams for $displayClass',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards({
    required int available,
    required int completed,
    required int avgScore,
    required int totalXp,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final cardWidth = isDesktop ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard('Available Tests', '$available', Icons.pending_actions_rounded, const Color(0xFF06B6D4), cardWidth),
            _buildStatCard('Completed Tests', '$completed', Icons.task_alt_rounded, const Color(0xFF10B981), cardWidth),
            _buildStatCard('Average Mastery', '$avgScore%', Icons.insights_rounded, const Color(0xFFA855F7), cardWidth),
            _buildStatCard('Test XP Earned', '+$totalXp XP', Icons.bolt_rounded, Colors.amber, cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            // Search Bar
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1538),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search assessments by title, subject, or chapter...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Available', 'Completed', 'Upcoming'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedFilter = filter),
                  backgroundColor: const Color(0xFF0F1538),
                  selectedColor: const Color(0xFF6C57FF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF6C57FF) : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentCard(AssessmentModel assessment, String studentId, String studentName) {
    final hasSubmitted = assessment.submissions.containsKey(studentId);
    final submissionStatus = assessment.submissions[studentId]; // 'submitted' or 'evaluated'
    final score = assessment.scores[studentId];
    final feedback = assessment.feedback[studentId];
    final isOverdue = DateTime.now().isAfter(assessment.dueDate);
    final isUpcoming = DateTime.now().isBefore(assessment.scheduledDate);

    Color statusColor = const Color(0xFF06B6D4);
    String statusText = 'Available';

    if (submissionStatus == 'evaluated') {
      statusColor = const Color(0xFF10B981);
      final pct = assessment.totalMarks > 0 ? (((score ?? 0) / assessment.totalMarks) * 100).round() : 0;
      statusText = 'Score: ${(score ?? 0).toStringAsFixed(0)}/${assessment.totalMarks} ($pct%)';
    } else if (submissionStatus == 'submitted') {
      statusColor = Colors.amber;
      statusText = 'Submitted • Pending Evaluation';
    } else if (isOverdue) {
      statusColor = Colors.redAccent;
      statusText = 'Past Due';
    } else if (isUpcoming) {
      statusColor = const Color(0xFFA855F7);
      statusText = 'Upcoming';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSubmitted
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFF6C57FF).withOpacity(0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type & Subject badges + Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C57FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assessment.subject.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFA855F7),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assessment.type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              assessment.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (assessment.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                assessment.description,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Metadata Row: Marks, Duration, Due Date
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetaPill(Icons.star_rounded, '${assessment.totalMarks} Marks', Colors.amber),
                _buildMetaPill(Icons.timer_outlined, '${assessment.durationMinutes} Mins', const Color(0xFF06B6D4)),
                _buildMetaPill(
                  Icons.calendar_today_rounded,
                  'Due: ${DateFormat('MMM dd, hh:mm a').format(assessment.dueDate)}',
                  Colors.white60,
                ),
                if (assessment.questions.isNotEmpty)
                  _buildMetaPill(Icons.help_outline_rounded, '${assessment.questions.length} Questions', Colors.white60),
              ],
            ),

            // Teacher Feedback (if evaluated)
            if (feedback != null && feedback.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.rate_review_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Teacher Feedback: "$feedback"',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!hasSubmitted)
                  ElevatedButton.icon(
                    onPressed: () {
                      AssessmentTakingDialog.show(
                        context,
                        assessment: assessment,
                        studentId: studentId,
                        studentName: studentName,
                        isReviewMode: false,
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Assessment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C57FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      AssessmentTakingDialog.show(
                        context,
                        assessment: assessment,
                        studentId: studentId,
                        studentName: studentName,
                        isReviewMode: true,
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('View Results & Explanations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF141A42),
                      foregroundColor: const Color(0xFFA855F7),
                      side: const BorderSide(color: Color(0xFF6C57FF)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6C57FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFA855F7), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Assessments Found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tests match your search query.'
                  : 'You have no scheduled assessments at this time.',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
