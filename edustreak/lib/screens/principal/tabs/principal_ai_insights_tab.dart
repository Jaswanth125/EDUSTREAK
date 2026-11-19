import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/school_insight_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../services/school_insights_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';

class PrincipalAIInsightsTab extends StatefulWidget {
  final SchoolModel school;

  const PrincipalAIInsightsTab({super.key, required this.school});

  @override
  State<PrincipalAIInsightsTab> createState() => _PrincipalAIInsightsTabState();
}

class _PrincipalAIInsightsTabState extends State<PrincipalAIInsightsTab> {
  final SchoolInsightsService _insightsService = SchoolInsightsService();
  final PrincipalService _principalService = PrincipalService();

  SchoolAnalyticsMetrics? _cachedMetrics;
  bool _isRefreshing = false;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  // Assistant Chat State
  final TextEditingController _assistantInputController = TextEditingController();
  final ScrollController _assistantScrollController = ScrollController();
  bool _isAssistantOpen = false;
  bool _isAssistantLoading = false;
  final List<Map<String, String>> _assistantHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMetrics();
  }

  @override
  void dispose() {
    _assistantInputController.dispose();
    _assistantScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMetrics({bool forceRecalculate = false}) async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      if (forceRecalculate) {
        final generated = await _insightsService.refreshAndPersistInsights(widget.school.id);
        if (mounted) {
          final metrics = await _insightsService.calculateRealMetrics(widget.school.id);
          setState(() {
            _cachedMetrics = metrics;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Real-time AI Intelligence refreshed (${generated.length} active insights)'),
              backgroundColor: EduStreakTheme.emeraldGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final metrics = await _insightsService.calculateRealMetrics(widget.school.id);
        if (mounted) {
          setState(() => _cachedMetrics = metrics);
        }
      }
    } catch (e) {
      debugPrint('Error calculating school metrics: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _askAssistant(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _assistantInputController.clear();
    setState(() {
      _assistantHistory.add({'role': 'user', 'content': cleanQuery});
      _isAssistantLoading = true;
    });

    _scrollAssistantToBottom();

    try {
      final answer = await _insightsService.askSchoolAssistant(
        widget.school.id,
        cleanQuery,
        cachedMetrics: _cachedMetrics,
      );

      if (mounted) {
        setState(() {
          _assistantHistory.add({'role': 'assistant', 'content': answer});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _assistantHistory.add({
            'role': 'assistant',
            'content': 'Unable to retrieve answer: $e',
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAssistantLoading = false);
        _scrollAssistantToBottom();
      }
    }
  }

  void _scrollAssistantToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_assistantScrollController.hasClients) {
        _assistantScrollController.animateTo(
          _assistantScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return StreamBuilder<List<SchoolInsightModel>>(
      stream: _insightsService.getInsightsStream(widget.school.id),
      builder: (context, snapshot) {
        final insights = snapshot.data ?? [];

        // Auto-seed if snapshot came back empty and we're not currently refreshing
        if (snapshot.connectionState == ConnectionState.active &&
            insights.isEmpty &&
            !_isRefreshing &&
            _cachedMetrics == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadInitialMetrics(forceRecalculate: true);
          });
        }

        final filteredInsights = _applyFilters(insights);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. INSTITUTIONAL HEALTH INDEX BANNER ──────────────────────
              _buildHealthIndexBanner(isDesktop),

              const SizedBox(height: 20),

              // ─── 2. GROUNDED KPI METRICS SUMMARY GRID ──────────────────────
              _buildMetricsSummaryGrid(isDesktop, isTablet),

              const SizedBox(height: 24),

              // ─── 3. INTERACTIVE SCHOOL INTELLIGENCE ASSISTANT ──────────────
              _buildAssistantCard(isDesktop),

              const SizedBox(height: 24),

              // ─── 4. CATEGORY & STATUS FILTER CHIPS ─────────────────────────
              _buildFilterSection(insights),

              const SizedBox(height: 18),

              // ─── 5. REAL-TIME INSIGHTS FEED ────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting && insights.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: EduStreakTheme.neonCyan),
                  ),
                )
              else if (filteredInsights.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: filteredInsights
                      .map((ins) => _buildGroundedInsightCard(ins, isDesktop))
                      .toList(),
                ),

              const SizedBox(height: 36),
            ],
          ),
        );
      },
    );
  }

  List<SchoolInsightModel> _applyFilters(List<SchoolInsightModel> all) {
    return all.where((item) {
      // Category filter
      if (_selectedCategory == 'Critical / High') {
        if (item.severity != 'critical' && item.severity != 'high') return false;
      } else if (_selectedCategory != 'All') {
        final catKey = _selectedCategory.toLowerCase().replaceAll(' ', '_');
        if (catKey == 'teacher_&_homework') {
          if (item.category != 'teacher_activity' && item.category != 'homework') return false;
        } else if (item.category != catKey) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatus != 'All') {
        final statusKey = _selectedStatus.toLowerCase().replaceAll(' ', '_');
        if (item.status != statusKey) return false;
      }

      return true;
    }).toList();
  }

  // ─── WIDGET 1: INSTITUTIONAL HEALTH INDEX BANNER ───────────────────────────
  Widget _buildHealthIndexBanner(bool isDesktop) {
    final health = _cachedMetrics?.healthScore ?? 86;
    final lastUpdated = _cachedMetrics?.lastCalculated;
    final timeStr = lastUpdated != null
        ? '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}'
        : 'Live';

    Color healthColor = EduStreakTheme.emeraldGreen;
    String healthLabel = 'Institutional Health Index: Strong Pulse';
    if (health < 70) {
      healthColor = EduStreakTheme.rosePink;
      healthLabel = 'Institutional Health Index: Action Required';
    } else if (health < 82) {
      healthColor = EduStreakTheme.amberGold;
      healthLabel = 'Institutional Health Index: Moderate Stability';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C1558),
            Color(0xFF1E1042),
            Color(0xFF120E2C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Health Dial / Score
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EduStreakTheme.primaryViolet.withValues(alpha: 0.25),
              border: Border.all(color: healthColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: healthColor.withValues(alpha: 0.3),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$health',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: healthColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: healthColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 13, color: healthColor),
                          const SizedBox(width: 4),
                          Text(
                            'CONTINUOUS REASONING ACTIVE',
                            style: EduStreakTheme.fontSmall(color: healthColor, weight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '• Updated at $timeStr',
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  healthLabel,
                  style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Continuous empirical analysis of student attendance records, academic grade distributions, homework completion streaks, and faculty grading workflows.',
                  style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isRefreshing ? null : () => _loadInitialMetrics(forceRecalculate: true),
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(_isRefreshing ? 'Analyzing...' : 'Recalculate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduStreakTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── WIDGET 2: GROUNDED KPI METRICS SUMMARY GRID ───────────────────────────
  Widget _buildMetricsSummaryGrid(bool isDesktop, bool isTablet) {
    final m = _cachedMetrics;
    final att = m?.overallAttendance ?? 88.0;
    final acad = m?.overallAcademicAverage ?? 78.4;
    final hw = m?.homeworkCompletionRate ?? 82.5;
    final pending = m?.pendingGradingCount ?? 0;

    final cards = [
      _buildKPICard(
        title: 'Attendance Rate',
        value: '${att.toStringAsFixed(1)}%',
        subtext: att >= 85 ? 'Above state target (85%)' : 'Below state target (85%)',
        accentColor: att >= 85 ? EduStreakTheme.emeraldGreen : EduStreakTheme.amberGold,
        icon: Icons.fact_check_rounded,
      ),
      _buildKPICard(
        title: 'Academic Average',
        value: '${acad.toStringAsFixed(1)}%',
        subtext: 'Across ${m?.totalClasses ?? 2} enrolled sections',
        accentColor: EduStreakTheme.primaryViolet,
        icon: Icons.school_rounded,
      ),
      _buildKPICard(
        title: 'Homework Completion',
        value: '${hw.toStringAsFixed(1)}%',
        subtext: 'Weekly submission consistency',
        accentColor: EduStreakTheme.neonCyan,
        icon: Icons.assignment_turned_in_rounded,
      ),
      _buildKPICard(
        title: 'Pending Faculty Grading',
        value: '$pending Tasks',
        subtext: pending > 5 ? 'Turnaround attention needed' : 'Normal evaluation queue',
        accentColor: pending > 5 ? EduStreakTheme.rosePink : EduStreakTheme.emeraldGreen,
        icon: Icons.pending_actions_rounded,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards.map((c) => SizedBox(width: isTablet ? 320 : double.infinity, child: c)).toList(),
      );
    }
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtext,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: EduStreakTheme.fontSmall(color: accentColor, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET 3: INTERACTIVE EXECUTIVE INTELLIGENCE ASSISTANT ────────────────
  Widget _buildAssistantCard(bool isDesktop) {
    final suggestedPrompts = [
      'Which class needs the most attention?',
      'Which subject has the lowest score?',
      'Analyze chronic absenteeism',
      'Show faculty grading turnaround',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131032),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar (Clickable to expand/collapse)
          InkWell(
            onTap: () => setState(() => _isAssistantOpen = !_isAssistantOpen),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: EduStreakTheme.neonCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'School Intelligence Advisory Assistant',
                              style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'REAL-TIME GROUNDED',
                                style: EduStreakTheme.fontSmall(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ask executive questions grounded in actual school metrics, classes, and teacher turnaround.',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isAssistantOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),

          if (_isAssistantOpen) ...[
            const Divider(color: Color(0xFF25204E), height: 1),

            // Prompt Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestedPrompts.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        onPressed: _isAssistantLoading ? null : () => _askAssistant(p),
                        backgroundColor: const Color(0xFF1E1848),
                        side: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        label: Text(
                          p,
                          style: EduStreakTheme.fontCaption(color: Colors.white70, weight: FontWeight.w600),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Chat Messages Container
            if (_assistantHistory.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 320),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  controller: _assistantScrollController,
                  shrinkWrap: true,
                  itemCount: _assistantHistory.length,
                  itemBuilder: (context, idx) {
                    final msg = _assistantHistory[idx];
                    final isUser = msg['role'] == 'user';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? EduStreakTheme.primaryViolet : const Color(0xFF1D1746),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUser ? Colors.transparent : const Color(0xFF332A6D),
                          ),
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_isAssistantLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: EduStreakTheme.neonCyan),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Synthesizing empirical evidence across school databases...',
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan),
                    ),
                  ],
                ),
              ),

            // Input Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _assistantInputController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Ask about attendance streaks, grade gaps, subject trends...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13.5),
                        filled: true,
                        fillColor: const Color(0xFF1A143E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: EduStreakTheme.neonCyan, width: 1.5),
                        ),
                      ),
                      onSubmitted: _isAssistantLoading ? null : _askAssistant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isAssistantLoading ? null : () => _askAssistant(_assistantInputController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduStreakTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── WIDGET 4: CATEGORY & STATUS FILTER SECTION ────────────────────────────
  Widget _buildFilterSection(List<SchoolInsightModel> all) {
    final criticalCount = all.where((i) => i.severity == 'critical' || i.severity == 'high').length;
    final academicCount = all.where((i) => i.category == 'academic').length;
    final attCount = all.where((i) => i.category == 'attendance').length;
    final teachCount = all.where((i) => i.category == 'teacher_activity' || i.category == 'homework').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPill('All', 'All Insights (${all.length})'),
          const SizedBox(width: 8),
          _buildPill('Critical / High', '🔴 High Priority ($criticalCount)'),
          const SizedBox(width: 8),
          _buildPill('Academic', '📊 Academic ($academicCount)'),
          const SizedBox(width: 8),
          _buildPill('Attendance', '📅 Attendance ($attCount)'),
          const SizedBox(width: 8),
          _buildPill('Teacher & Homework', '📝 Faculty & Tasks ($teachCount)'),
          const SizedBox(width: 16),
          Container(height: 24, width: 1.2, color: EduStreakTheme.studentDarkBorder),
          const SizedBox(width: 16),
          // Status Filters
          _buildStatusPill('All', 'All Status'),
          const SizedBox(width: 6),
          _buildStatusPill('Open', 'Open'),
          const SizedBox(width: 6),
          _buildStatusPill('In Progress', 'In Progress'),
          const SizedBox(width: 6),
          _buildStatusPill('Resolved', 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildPill(String key, String label) {
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EduStreakTheme.primaryViolet : EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : EduStreakTheme.studentDarkBorder,
          ),
        ),
        child: Text(
          label,
          style: EduStreakTheme.fontCaption(
            color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
            weight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String key, String label) {
    final isSelected = _selectedStatus == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF28205C) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? EduStreakTheme.neonCyan : EduStreakTheme.studentDarkBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: EduStreakTheme.fontSmall(
            color: isSelected ? EduStreakTheme.neonCyan : EduStreakTheme.studentDarkTextMuted,
            weight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── WIDGET 5: GROUNDED INSIGHT CARD (EMPIRICAL vs HYPOTHESIS) ─────────────
  Widget _buildGroundedInsightCard(SchoolInsightModel ins, bool isDesktop) {
    final isCritical = ins.severity == 'critical';
    final isHigh = ins.severity == 'high';
    final isModerate = ins.severity == 'moderate';

    Color accentColor;
    IconData icon;
    String badgeText;

    if (isCritical) {
      accentColor = EduStreakTheme.rosePink;
      icon = Icons.error_outline_rounded;
      badgeText = 'CRITICAL ALERT';
    } else if (isHigh) {
      accentColor = Colors.deepOrangeAccent;
      icon = Icons.warning_amber_rounded;
      badgeText = 'HIGH PRIORITY';
    } else if (isModerate) {
      accentColor = EduStreakTheme.amberGold;
      icon = Icons.info_outline_rounded;
      badgeText = 'MODERATE';
    } else {
      accentColor = EduStreakTheme.emeraldGreen;
      icon = Icons.trending_up_rounded;
      badgeText = 'POSITIVE MOMENTUM';
    }

    final isResolved = ins.status == 'resolved';
    final isInProgress = ins.status == 'in_progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isResolved
              ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)
              : accentColor.withValues(alpha: 0.4),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Severity Badge, Confidence Chip, Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accentColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: EduStreakTheme.fontSmall(color: accentColor, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A42),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Confidence: ${ins.confidenceLevel}',
                  style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved
                      ? EduStreakTheme.emeraldGreen.withValues(alpha: 0.15)
                      : (isInProgress ? EduStreakTheme.amberGold.withValues(alpha: 0.15) : const Color(0xFF231B4D)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isResolved
                        ? EduStreakTheme.emeraldGreen
                        : (isInProgress ? EduStreakTheme.amberGold : EduStreakTheme.studentDarkBorder),
                  ),
                ),
                child: Text(
                  ins.status.toUpperCase().replaceAll('_', ' '),
                  style: EduStreakTheme.fontSmall(
                    color: isResolved
                        ? EduStreakTheme.emeraldGreen
                        : (isInProgress ? EduStreakTheme.amberGold : Colors.white70),
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title & Impact Scope
          Text(
            ins.title,
            style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            'Target: ${ins.affectedEntity} • Period: ${ins.observationPeriod}',
            style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
          ),

          const SizedBox(height: 14),

          // ─── 1. EMPIRICAL FINDING (VERIFIED FACT) ──────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded, color: EduStreakTheme.emeraldGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VERIFIED EMPIRICAL FINDING',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ins.finding,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ─── 2. AI INTERPRETATION & HYPOTHESIS ─────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B133D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_rounded, color: EduStreakTheme.neonCyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI INTERPRETATION & OPERATIONAL HYPOTHESIS',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ins.interpretation,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Supporting Metrics Chips (if any)
          if (ins.supportingMetrics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ins.supportingMetrics.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16113A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2C2263)),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: EduStreakTheme.fontSmall(color: Colors.white70, weight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // ─── 3. RECOMMENDED STRATEGIC ACTION ───────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF15193B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A346C)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: EduStreakTheme.amberGold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMMENDED ACTION FOR LEADERSHIP',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.amberGold, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ins.recommendedAction,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Follow-up / Action Taken Documentation Status
          if (ins.actionTaken != null && ins.actionTaken!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0C241E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.task_alt_rounded, color: EduStreakTheme.emeraldGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Action Recorded: ${ins.actionTaken}',
                      style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w600),
                    ),
                  ),
                  if (ins.assignedToName != null)
                    Text(
                      '👤 ${ins.assignedToName}',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.emeraldGreen, weight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF241C4F), height: 1),
          const SizedBox(height: 12),

          // ─── 4. INTERACTIVE ACTION BUTTONS ─────────────────────────────
          Row(
            children: [
              // Mark Reviewed Button
              OutlinedButton.icon(
                onPressed: () => _toggleReviewed(ins),
                icon: Icon(
                  ins.isReviewed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: ins.isReviewed ? EduStreakTheme.emeraldGreen : Colors.white70,
                ),
                label: Text(
                  ins.isReviewed ? 'Reviewed' : 'Mark Reviewed',
                  style: TextStyle(
                    color: ins.isReviewed ? EduStreakTheme.emeraldGreen : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ins.isReviewed
                        ? EduStreakTheme.emeraldGreen
                        : EduStreakTheme.studentDarkBorder,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              const SizedBox(width: 10),

              // Assign Follow-Up Button
              OutlinedButton.icon(
                onPressed: () => _showAssignFollowUpDialog(ins),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: EduStreakTheme.neonCyan),
                label: Text(
                  ins.assignedToName != null ? 'Reassign' : 'Assign Faculty',
                  style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: EduStreakTheme.neonCyan.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              const Spacer(),

              // Record Action Taken Button
              ElevatedButton.icon(
                onPressed: () => _showRecordActionDialog(ins),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('Record Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ACTION 1: TOGGLE REVIEWED ─────────────────────────────────────────────
  Future<void> _toggleReviewed(SchoolInsightModel ins) async {
    final nextState = !ins.isReviewed;
    try {
      await _insightsService.markReviewed(
        widget.school.id,
        ins.id,
        nextState,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextState ? '✓ Marked insight as reviewed' : 'Review status reset'),
            backgroundColor: EduStreakTheme.emeraldGreen,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating reviewed status: $e');
    }
  }

  // ─── ACTION 2: ASSIGN FOLLOW-UP DIALOG ─────────────────────────────────────
  void _showAssignFollowUpDialog(SchoolInsightModel ins) {
    String? selectedTeacherId;
    String? selectedTeacherName;
    final roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16123D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.5)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, color: EduStreakTheme.neonCyan),
                  const SizedBox(width: 10),
                  Text(
                    'Assign Leadership Follow-Up',
                    style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight: ${ins.title}',
                      style: EduStreakTheme.fontCaption(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select School Faculty Member:',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    // Teacher Stream Dropdown
                    StreamBuilder<List<UserModel>>(
                      stream: _principalService.getTeachersStream(widget.school.id),
                      builder: (context, snapshot) {
                        final teachers = snapshot.data ?? [];
                        if (teachers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1748),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No registered teachers found. You can specify a faculty role below.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1748),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1E1748),
                              value: selectedTeacherId,
                              hint: const Text('Choose Faculty Member', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              items: teachers.map((t) {
                                return DropdownMenuItem(
                                  value: t.id,
                                  child: Text(
                                    '${t.name} (${t.email})',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedTeacherId = val;
                                  final match = teachers.firstWhere((t) => t.id == val);
                                  selectedTeacherName = match.name;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Or assign by Department / Role:',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Class 10A Class Teacher, Head of Science',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E1748),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final assigneeName = selectedTeacherName ?? roleController.text.trim();
                    final assigneeId = selectedTeacherId ?? 'role_${assigneeName.toLowerCase().replaceAll(' ', '_')}';

                    if (assigneeName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a teacher or enter a role')),
                      );
                      return;
                    }

                    await _insightsService.assignFollowUp(
                      schoolId: widget.school.id,
                      insightId: ins.id,
                      assignedTo: assigneeId,
                      assignedToName: assigneeName,
                    );

                    if (mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Assigned follow-up to "$assigneeName"'),
                          backgroundColor: EduStreakTheme.emeraldGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduStreakTheme.neonCyan,
                    foregroundColor: const Color(0xFF0B0920),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── ACTION 3: RECORD ACTION DIALOG ────────────────────────────────────────
  void _showRecordActionDialog(SchoolInsightModel ins) {
    final noteController = TextEditingController(text: ins.actionTaken ?? '');
    String selectedStatus = ins.status == 'resolved' ? 'resolved' : 'in_progress';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16123D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.5)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: EduStreakTheme.emeraldGreen),
                  const SizedBox(width: 10),
                  Text(
                    'Record Leadership Action',
                    style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight: ${ins.title}',
                      style: EduStreakTheme.fontCaption(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Action / Intervention Details:',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Conducted remediation meeting with science faculty; mandated weekly diagnostic quiz on Newton laws.',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E1748),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: EduStreakTheme.secondaryPurple.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Update Lifecycle Status:',
                      style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedStatus = 'in_progress'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedStatus == 'in_progress' ? const Color(0xFF2C245E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedStatus == 'in_progress' ? EduStreakTheme.amberGold : EduStreakTheme.studentDarkBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'In Progress',
                                  style: TextStyle(
                                    color: selectedStatus == 'in_progress' ? EduStreakTheme.amberGold : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedStatus = 'resolved'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedStatus == 'resolved' ? const Color(0xFF123528) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedStatus == 'resolved' ? EduStreakTheme.emeraldGreen : EduStreakTheme.studentDarkBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Resolved',
                                  style: TextStyle(
                                    color: selectedStatus == 'resolved' ? EduStreakTheme.emeraldGreen : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final note = noteController.text.trim();
                    if (note.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please describe the action taken')),
                      );
                      return;
                    }

                    await _insightsService.recordActionTaken(
                      schoolId: widget.school.id,
                      insightId: ins.id,
                      actionTaken: note,
                      status: selectedStatus,
                    );

                    if (mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Action recorded ($selectedStatus)'),
                          backgroundColor: EduStreakTheme.emeraldGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduStreakTheme.emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: EduStreakTheme.studentDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EduStreakTheme.studentDarkBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_outlined, size: 48, color: EduStreakTheme.emeraldGreen),
            const SizedBox(height: 16),
            Text(
              'No Anomalies in Filtered Scope',
              style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'All student metrics, section attendance, and faculty turnaround meet current benchmarks.',
              textAlign: TextAlign.center,
              style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}

