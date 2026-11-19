import 'package:flutter/material.dart';
import '../../services/platform_settings_service.dart';
import '../../services/audit_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../widgets/responsive/responsive_dialog.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _settingsService = PlatformSettingsService();
  final _auditService = AuditService();

  Map<String, dynamic>? _aiHealthResult;
  bool _isCheckingAiHealth = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAiHealth();
  }

  Future<void> _checkAiHealth() async {
    setState(() => _isCheckingAiHealth = true);
    final res = await _settingsService.checkFastApiHealth();
    if (mounted) {
      setState(() {
        _aiHealthResult = res;
        _isCheckingAiHealth = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B1E),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform Settings & System Governance', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Gamification algorithms, state-wide broadcasts, AI service health, and immutable audit logs.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF26326E)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: EduStreakTheme.primaryViolet,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    tabs: const [
                      Tab(text: 'Gamification & Rules'),
                      Tab(text: 'Announcements'),
                      Tab(text: 'AI Service Health'),
                      Tab(text: 'System Audit Logs'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGamificationTab(),
                _buildAnnouncementsTab(),
                _buildAiHealthTab(),
                _buildAuditLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: GAMIFICATION & STREAK RULES ───────────────────────────────────
  Widget _buildGamificationTab() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _settingsService.getSettingsStream(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? {};
        final xpDaily = TextEditingController(text: '${settings['xpPerDailyStreak'] ?? 50}');
        final xpQuiz = TextEditingController(text: '${settings['xpPerQuizCompletion'] ?? 100}');
        final graceHours = TextEditingController(text: '${settings['streakGracePeriodHours'] ?? 24}');
        bool maintenance = settings['maintenanceMode'] ?? false;
        bool regOpen = settings['registrationOpen'] ?? true;

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1535),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduStreakTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gamification Formula & Progression Thresholds', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Configures points awarded across students in all schools. Real-time updates without app reinstall.', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xpDaily,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'XP Per Daily Streak (Default: 50)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: xpQuiz,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'XP Per Practice Arena Quiz (Default: 100)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: graceHours,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Streak Grace Window (Hours: 24)'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: Color(0xFF222B5C)),
                const SizedBox(height: 16),

                Text('Platform Availability & Access Control', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 12),

                SwitchListTile(
                  title: const Text('Maintenance Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Temporarily pauses all student and teacher logins while keeping Central Admin accessible.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: maintenance,
                  activeColor: Colors.orangeAccent,
                  onChanged: (val) async {
                    await _settingsService.updateSettings({'maintenanceMode': val});
                  },
                ),

                SwitchListTile(
                  title: const Text('Public Registration Open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enables on-demand student/parent account registration.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: regOpen,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) async {
                    await _settingsService.updateSettings({'registrationOpen': val});
                  },
                ),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _settingsService.updateSettings({
                        'xpPerDailyStreak': int.tryParse(xpDaily.text.trim()) ?? 50,
                        'xpPerQuizCompletion': int.tryParse(xpQuiz.text.trim()) ?? 100,
                        'streakGracePeriodHours': int.tryParse(graceHours.text.trim()) ?? 24,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gamification settings saved to Firestore!')));
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Platform Settings'),
                    style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 2: ANNOUNCEMENTS ─────────────────────────────────────────────────
  Widget _buildAnnouncementsTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Educational Broadcasts', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            ElevatedButton.icon(
              onPressed: _showBroadcastDialog,
              icon: const Icon(Icons.campaign_rounded, size: 18),
              label: const Text('Broadcast Announcement'),
              style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<PlatformAnnouncement>>(
            stream: _settingsService.getAnnouncementsStream(),
            builder: (context, snapshot) {
              final announcements = snapshot.data ?? [];
              if (announcements.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_outlined, size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text('No active announcements.', style: EduStreakTheme.fontBody(color: Colors.white70)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: announcements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  final isUrgent = ann.priority == 'URGENT';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1535),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUrgent ? Colors.redAccent : EduStreakTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isUrgent ? Colors.redAccent : EduStreakTheme.primaryViolet).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.campaign_rounded, color: isUrgent ? Colors.redAccent : EduStreakTheme.primaryVioletLight, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(ann.title, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isUrgent ? Colors.red.withValues(alpha: 0.2) : Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(ann.priority, style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                    child: Text('Audience: ${ann.targetAudience}', style: const TextStyle(color: EduStreakTheme.primaryVioletLight, fontSize: 10)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(ann.message, style: EduStreakTheme.fontBodySmall(color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text('Broadcasted: ${ann.createdAt.toIso8601String().substring(0, 16)}', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                          onPressed: () => _settingsService.deleteAnnouncement(ann.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── TAB 3: FASTAPI AI ASSISTANT HEALTH ───────────────────────────────────
  Widget _buildAiHealthTab() {
    final status = _aiHealthResult?['status'] ?? 'unknown';
    final latency = _aiHealthResult?['latencyMs'] ?? 0;
    final isOnline = status == 'online';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1535),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduStreakTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isOnline ? Colors.green : Colors.orangeAccent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: isOnline ? Colors.greenAccent : Colors.orangeAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EduStreak AI Teaching Assistant Microservice', style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700)),
                      Text('FastAPI Vector RAG Engine • Port 8000', style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isCheckingAiHealth ? null : _checkAiHealth,
                  icon: _isCheckingAiHealth
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Ping Health Status'),
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _buildHealthCard('Service Status', status.toUpperCase(), isOnline ? Colors.greenAccent : Colors.orangeAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildHealthCard('Latency', '$latency ms', Colors.cyanAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildHealthCard('Local Endpoint', 'http://127.0.0.1:8000', Colors.purpleAccent)),
              ],
            ),

            const SizedBox(height: 24),
            Text('Connected Capabilities', style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildCapabilityRow('/status/', 'Microservice health & Vector Store stats', isOnline),
            _buildCapabilityRow('/documents/', 'NCERT/SCERT Document ingestion pipeline', isOnline),
            _buildCapabilityRow('/query/', 'RAG semantic document querying for student buddy', isOnline),
            _buildCapabilityRow('/quiz/interactive/', 'Dynamic MCQ generation tailored to student weaknesses', isOnline),
            _buildCapabilityRow('/summary/', 'Chapter-level smart conceptual summaries', isOnline),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141A42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String endpoint, String desc, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: active ? Colors.greenAccent : Colors.white30),
          const SizedBox(width: 10),
          Text(endpoint, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(width: 12),
          Text('— $desc', style: EduStreakTheme.fontCaption(color: Colors.white70)),
        ],
      ),
    );
  }

  // ─── TAB 4: SYSTEM AUDIT LOGS ─────────────────────────────────────────────
  Widget _buildAuditLogsTab() {
    return StreamBuilder<List<AuditRecord>>(
      stream: _auditService.getRecentAuditLogsStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 48, color: Colors.white24),
                const SizedBox(height: 12),
                Text('No audit records in database.', style: EduStreakTheme.fontBody(color: Colors.white70)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: EduStreakTheme.primaryVioletLight),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(log.action, style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700)),
                            const Spacer(),
                            Text(log.formattedTime, style: EduStreakTheme.fontCaption(color: EduStreakTheme.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: [${log.targetType.toUpperCase()}] ${log.targetId} • Admin: ${log.adminId}',
                          style: EduStreakTheme.fontCaption(color: EduStreakTheme.primaryVioletLight),
                        ),
                        if (log.details.isNotEmpty)
                          Text(
                            log.details.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                            style: EduStreakTheme.fontCaption(color: Colors.white70),
                          ),
                      ],
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

  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String audience = 'ALL';
    String priority = 'NORMAL';

    showAdaptiveEduStreakModal(
      context: context,
      maxWidth: 480,
      title: 'Send Educational Broadcast',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Broadcast Title')),
                const SizedBox(height: 12),
                TextField(controller: msgCtrl, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Broadcast Message Content')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: audience,
                  dropdownColor: const Color(0xFF141A42),
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Portals (Students, Teachers, Parents)')),
                    DropdownMenuItem(value: 'STUDENTS', child: Text('Students Only')),
                    DropdownMenuItem(value: 'TEACHERS', child: Text('Teachers Only')),
                    DropdownMenuItem(value: 'PARENTS', child: Text('Parents Only')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => audience = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: const Color(0xFF141A42),
                  decoration: const InputDecoration(labelText: 'Priority Level'),
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal Priority')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Urgent Notification (Red Banner)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => priority = val);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _settingsService.broadcastAnnouncement(
                      title: titleCtrl.text.trim(),
                      message: msgCtrl.text.trim(),
                      targetAudience: audience,
                      priority: priority,
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                  child: const Text('Send Announcement Broadcast'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
