import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/school_model.dart';
import '../../services/csv_import_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/responsive_breakpoints.dart';

class CsvImportDialog extends StatefulWidget {
  final SchoolModel school;
  final int initialTab; // 0: Students, 1: Teachers

  const CsvImportDialog({
    super.key,
    required this.school,
    this.initialTab = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required SchoolModel school,
    int initialTab = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CsvImportDialog(school: school, initialTab: initialTab),
    );
  }

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  final _csvService = CsvImportService();
  late int _activeTab; // 0: Students, 1: Teachers

  final _csvTextController = TextEditingController();
  bool _isValidating = false;
  bool _isImporting = false;

  CsvValidationResult? _studentValidation;
  CsvTeacherValidationResult? _teacherValidation;
  CsvImportSummary? _importSummary;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
  }

  @override
  void dispose() {
    _csvTextController.dispose();
    super.dispose();
  }

  void _loadSampleTemplate() {
    if (_activeTab == 0) {
      _csvTextController.text = CsvImportService.getStudentCsvTemplate();
    } else {
      _csvTextController.text = CsvImportService.getTeacherCsvTemplate();
    }
    setState(() {
      _studentValidation = null;
      _teacherValidation = null;
      _importSummary = null;
    });
  }

  void _copyTemplateToClipboard() {
    final template = _activeTab == 0
        ? CsvImportService.getStudentCsvTemplate()
        : CsvImportService.getTeacherCsvTemplate();

    Clipboard.setData(ClipboardData(text: template));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_activeTab == 0 ? 'Student' : 'Faculty'} CSV Template copied to clipboard!',
        ),
        backgroundColor: EduStreakTheme.emeraldGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _validateCsv() async {
    final text = _csvTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste or enter CSV content to validate.'),
          backgroundColor: EduStreakTheme.rosePink,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _studentValidation = null;
      _teacherValidation = null;
      _importSummary = null;
    });

    try {
      if (_activeTab == 0) {
        final result = await _csvService.validateCsv(
          csvContent: text,
          schoolId: widget.school.id,
        );
        if (mounted) setState(() => _studentValidation = result);
      } else {
        final result = await _csvService.validateTeacherCsv(
          csvContent: text,
          schoolId: widget.school.id,
        );
        if (mounted) setState(() => _teacherValidation = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: $e'),
            backgroundColor: EduStreakTheme.rosePink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _confirmAndImport() async {
    setState(() => _isImporting = true);

    try {
      if (_activeTab == 0 && _studentValidation != null) {
        final summary = await _csvService.executeImport(
          schoolId: widget.school.id,
          schoolCode: widget.school.code,
          rows: _studentValidation!.validRows,
        );
        if (mounted) setState(() => _importSummary = summary);
      } else if (_activeTab == 1 && _teacherValidation != null) {
        final summary = await _csvService.executeTeacherImport(
          schoolId: widget.school.id,
          schoolCode: widget.school.code,
          rows: _teacherValidation!.validRows,
        );
        if (mounted) setState(() => _importSummary = summary);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import execution failed: $e'),
            backgroundColor: EduStreakTheme.rosePink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final dialogWidth = isDesktop ? 760.0 : MediaQuery.of(context).size.width - 32;

    return Dialog(
      backgroundColor: const Color(0xFF111638),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF283168), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── DIALOG HEADER ──────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.file_upload_outlined,
                      color: EduStreakTheme.neonCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Institutional CSV Roster Import',
                          style: EduStreakTheme.fontHeading3(color: Colors.white),
                        ),
                        Text(
                          'School: ${widget.school.name} (${widget.school.code})',
                          style: EduStreakTheme.fontCaption(
                            color: EduStreakTheme.lavender,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── TAB SELECTOR: STUDENTS VS TEACHERS ──────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1029),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF232A5C)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Student Roster CSV',
                        icon: Icons.school_rounded,
                        isSelected: _activeTab == 0,
                        onTap: () {
                          setState(() {
                            _activeTab = 0;
                            _studentValidation = null;
                            _teacherValidation = null;
                            _importSummary = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Faculty / Teacher CSV',
                        icon: Icons.co_present_rounded,
                        isSelected: _activeTab == 1,
                        onTap: () {
                          setState(() {
                            _activeTab = 1;
                            _studentValidation = null;
                            _teacherValidation = null;
                            _importSummary = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── TEMPLATE & QUICK ACTIONS TOOLBAR ───────────────────────
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyTemplateToClipboard,
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Copy CSV Template'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EduStreakTheme.neonCyan,
                      side: const BorderSide(color: EduStreakTheme.neonCyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: _loadSampleTemplate,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Insert Sample Data'),
                    style: TextButton.styleFrom(
                      foregroundColor: EduStreakTheme.lavender,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── CONTENT AREA (SCROLLABLE) ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // CSV Input Box
                      TextField(
                        controller: _csvTextController,
                        maxLines: 6,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: _activeTab == 0
                              ? 'Paste student CSV text here (student_name, roll_number, class, section, etc.)...'
                              : 'Paste teacher CSV text here (teacher_name, employee_id, email, assigned_subjects, etc.)...',
                          hintStyle: TextStyle(
                            color: Colors.white30,
                            fontFamily: 'monospace',
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0C0F27),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF283168)),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Validate Button
                      ElevatedButton.icon(
                        onPressed: _isValidating ? null : _validateCsv,
                        icon: _isValidating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.fact_check_outlined, size: 18),
                        label: Text(_isValidating ? 'Validating CSV...' : 'Validate CSV Rows'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EduStreakTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Validation Results Preview (Student)
                      if (_activeTab == 0 && _studentValidation != null)
                        _buildStudentValidationPreview(_studentValidation!),

                      // Validation Results Preview (Teacher)
                      if (_activeTab == 1 && _teacherValidation != null)
                        _buildTeacherValidationPreview(_teacherValidation!),

                      // Import Summary Report
                      if (_importSummary != null)
                        _buildImportSummaryCard(_importSummary!),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── FOOTER ACTIONS ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 12),
                  if ((_studentValidation?.validRows.isNotEmpty ?? false) ||
                      (_teacherValidation?.validRows.isNotEmpty ?? false))
                    ElevatedButton.icon(
                      onPressed: _isImporting ? null : _confirmAndImport,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(
                        _isImporting
                            ? 'Committing Batch...'
                            : 'Confirm & Import to Roster',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EduStreakTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? EduStreakTheme.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: EduStreakTheme.fontCaption(
                color: isSelected ? Colors.white : EduStreakTheme.studentDarkTextMuted,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentValidationPreview(CsvValidationResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1332),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF283168)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBadge('Total: ${result.totalRows}', Colors.white70),
              const SizedBox(width: 8),
              _buildBadge('Valid: ${result.validRows.length}', EduStreakTheme.emeraldGreen),
              const SizedBox(width: 8),
              _buildBadge('Invalid: ${result.invalidRows.length}', EduStreakTheme.rosePink),
            ],
          ),
          if (result.globalErrors.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...result.globalErrors.map(
              (err) => Text(
                '• $err',
                style: const TextStyle(color: EduStreakTheme.rosePink, fontSize: 12),
              ),
            ),
          ],
          if (result.invalidRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Row Errors:',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...result.invalidRows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Row ${r.rowIndex} [${r.studentName.isNotEmpty ? r.studentName : "Unknown"}]: ${r.error}',
                  style: const TextStyle(color: EduStreakTheme.rosePink, fontSize: 12),
                ),
              ),
            ),
          ],
          if (result.validRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Valid Rows Preview (${result.validRows.length}):',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...result.validRows.take(5).map(
              (r) => Text(
                '✓ ${r.studentName} | Roll: ${r.rollNumber} | ${r.classLabel}',
                style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12),
              ),
            ),
            if (result.validRows.length > 5)
              Text(
                '+ ${result.validRows.length - 5} more valid rows ready for import...',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeacherValidationPreview(CsvTeacherValidationResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1332),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF283168)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBadge('Total: ${result.totalRows}', Colors.white70),
              const SizedBox(width: 8),
              _buildBadge('Valid: ${result.validRows.length}', EduStreakTheme.emeraldGreen),
              const SizedBox(width: 8),
              _buildBadge('Invalid: ${result.invalidRows.length}', EduStreakTheme.rosePink),
            ],
          ),
          if (result.globalErrors.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...result.globalErrors.map(
              (err) => Text(
                '• $err',
                style: const TextStyle(color: EduStreakTheme.rosePink, fontSize: 12),
              ),
            ),
          ],
          if (result.invalidRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Row Errors:',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...result.invalidRows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Row ${r.rowIndex} [${r.teacherName.isNotEmpty ? r.teacherName : "Unknown"}]: ${r.error}',
                  style: const TextStyle(color: EduStreakTheme.rosePink, fontSize: 12),
                ),
              ),
            ),
          ],
          if (result.validRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Valid Faculty Preview (${result.validRows.length}):',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...result.validRows.take(5).map(
              (r) => Text(
                '✓ ${r.teacherName} | Emp: ${r.employeeId} | ${r.assignedSubjects.join(", ")}',
                style: const TextStyle(color: EduStreakTheme.neonCyan, fontSize: 12),
              ),
            ),
            if (result.validRows.length > 5)
              Text(
                '+ ${result.validRows.length - 5} more faculty rows ready for import...',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportSummaryCard(CsvImportSummary summary) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B241C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduStreakTheme.emeraldGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: EduStreakTheme.emeraldGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Import Completed Successfully!',
                style: TextStyle(
                  color: EduStreakTheme.emeraldGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _activeTab == 0
                ? '${summary.studentsCreated} student records imported to roster with status "Not Registered". Students can now self-register using their School Code and Roll Number.'
                : '${summary.teachersCreated} faculty records imported to roster with status "Not Registered". Teachers can now claim their accounts with their Employee ID.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
