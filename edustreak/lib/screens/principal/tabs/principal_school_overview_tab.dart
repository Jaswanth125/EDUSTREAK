import 'package:flutter/material.dart';
import '../../../../models/school_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/principal_service.dart';
import '../../../../utils/edustreak_theme.dart';
import '../../../../utils/responsive_breakpoints.dart';
import '../../../../widgets/responsive/responsive_dialog.dart';

class PrincipalSchoolOverviewTab extends StatefulWidget {
  final SchoolModel school;
  final UserModel principal;

  const PrincipalSchoolOverviewTab({
    super.key,
    required this.school,
    required this.principal,
  });

  @override
  State<PrincipalSchoolOverviewTab> createState() => _PrincipalSchoolOverviewTabState();
}

class _PrincipalSchoolOverviewTabState extends State<PrincipalSchoolOverviewTab> {
  final _principalService = PrincipalService();
  late SchoolModel _school;

  @override
  void initState() {
    super.initState();
    _school = widget.school;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : (isTablet ? 20 : 16),
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── INSTITUTION HEADER CARD ────────────────────────────────────
          _buildInstitutionHeader(isDesktop),

          const SizedBox(height: 24),

          // ─── INFRASTRUCTURE STATS GRID ──────────────────────────────────
          _buildInfrastructureGrid(isDesktop, isTablet),

          const SizedBox(height: 24),

          // ─── TWO-COLUMN DETAILS ─────────────────────────────────────────
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAdministrativeDetailsCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildDepartmentalBreakdownCard()),
              ],
            )
          else ...[
            _buildAdministrativeDetailsCard(),
            const SizedBox(height: 20),
            _buildDepartmentalBreakdownCard(),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInstitutionHeader(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final contentPadding = isCompact ? 16.0 : 24.0;

        final badges = Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _school.type.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _school.type.color.withValues(alpha: 0.4)),
              ),
              child: Text(
                _school.type.displayName.toUpperCase(),
                style: EduStreakTheme.fontSmall(color: _school.type.color, weight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                _school.status.toUpperCase(),
                style: EduStreakTheme.fontSmall(color: EduStreakTheme.emeraldGreen, weight: FontWeight.w700),
              ),
            ),
          ],
        );

        final editButton = ElevatedButton.icon(
          onPressed: _showEditPermittedSettingsModal,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: const Text('Edit Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: EduStreakTheme.primaryViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(contentPadding),
          decoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: EduStreakTheme.activePillGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: badges),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _school.name,
                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_school.address}, ${_school.mandal} Mandal, ${_school.district} District, ${_school.state} - ${_school.pincode}',
                      style: EduStreakTheme.fontBody(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: editButton,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: EduStreakTheme.activePillGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          badges,
                          const SizedBox(height: 10),
                          Text(
                            _school.name,
                            style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_school.address}, ${_school.mandal} Mandal, ${_school.district} District, ${_school.state} - ${_school.pincode}',
                            style: EduStreakTheme.fontBody(color: EduStreakTheme.studentDarkTextMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    editButton,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInfrastructureGrid(bool isDesktop, bool isTablet) {
    final stats = [
      {'title': 'Enrolled Students', 'value': '${_school.totalStudents}', 'icon': Icons.school_rounded, 'color': EduStreakTheme.primaryViolet},
      {'title': 'Faculty Members', 'value': '${_school.totalTeachers}', 'icon': Icons.supervisor_account_rounded, 'color': EduStreakTheme.neonCyan},
      {'title': 'Academic Classes', 'value': 'Grades 6 - 10', 'icon': Icons.meeting_room_rounded, 'color': EduStreakTheme.emeraldGreen},
      {'title': 'Curriculum Track', 'value': _school.curriculumTemplateId, 'icon': Icons.auto_stories_rounded, 'color': EduStreakTheme.amberGold},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final item = stats[index];
        final color = item['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EduStreakTheme.studentDarkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduStreakTheme.studentDarkBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['value'] as String,
                      style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['title'] as String,
                      style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdministrativeDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: EduStreakTheme.neonCyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Institutional Specifications',
                  style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSpecRow('Official School Code', _school.code, isProtected: true),
          _buildSpecRow('Board Affiliation', _school.type.displayName, isProtected: true),
          _buildSpecRow('Affiliation Number', _school.affiliationNumber, isProtected: true),
          _buildSpecRow('Academic Year', _school.academicYear),
          _buildSpecRow('Head of Institution', '${widget.principal.name} (Principal)'),
          _buildSpecRow('Institutional Phone', _school.contactPhone.isNotEmpty ? _school.contactPhone : '+91 94401 23456'),
          _buildSpecRow('Official Email', _school.contactEmail.isNotEmpty ? _school.contactEmail : 'principal@apgov.edu.in'),
          _buildSpecRow('Address Details', '${_school.address}, ${_school.mandal}'),
          _buildSpecRow('Postal PIN', _school.pincode.isNotEmpty ? _school.pincode : '521151'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isProtected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (isProtected) ...[
                  const Icon(Icons.lock_outline_rounded, size: 12, color: EduStreakTheme.amberGold),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkTextMuted, weight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: EduStreakTheme.fontCaption(
                color: isProtected ? EduStreakTheme.neonCyan : Colors.white,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentalBreakdownCard() {
    final departments = [
      {'name': 'Department of Mathematics', 'head': 'Mr. David Smith', 'teachers': 4, 'classes': 'Grades 6 - 10'},
      {'name': 'Department of Physical Science', 'head': 'Ms. Sarah Johnson', 'teachers': 5, 'classes': 'Grades 8 - 10'},
      {'name': 'Department of Biological Science', 'head': 'Dr. P. Anitha', 'teachers': 3, 'classes': 'Grades 8 - 10'},
      {'name': 'Department of Social Studies', 'head': 'Mr. R. V. Reddy', 'teachers': 4, 'classes': 'Grades 6 - 10'},
      {'name': 'Department of English', 'head': 'Mrs. L. Mary', 'teachers': 4, 'classes': 'Grades 6 - 10'},
      {'name': 'Department of First Language (Telugu)', 'head': 'Mr. G. Sastry', 'teachers': 4, 'classes': 'Grades 6 - 10'},
      {'name': 'Department of Physical Education & Arts', 'head': 'Mr. B. Prasad', 'teachers': 4, 'classes': 'Grades 6 - 10'},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: EduStreakTheme.studentDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EduStreakTheme.studentDarkBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_rounded, color: EduStreakTheme.primaryViolet, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Academic Departments & Faculty',
                  style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            children: departments.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF14193E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF232A60)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['name'] as String,
                            style: EduStreakTheme.fontCaption(color: Colors.white, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Head: ${d['head']} • ${d['classes']}',
                            style: EduStreakTheme.fontSmall(color: EduStreakTheme.studentDarkTextMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: EduStreakTheme.primaryViolet.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${d['teachers']} Faculty',
                        style: EduStreakTheme.fontSmall(color: EduStreakTheme.neonCyan, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── EDIT PERMITTED SETTINGS MODAL ────────────────────────────────────────
  void _showEditPermittedSettingsModal() {
    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController(text: _school.contactPhone);
    final emailController = TextEditingController(text: _school.contactEmail);
    final addressController = TextEditingController(text: _school.address);
    final mandalController = TextEditingController(text: _school.mandal);
    final pincodeController = TextEditingController(text: _school.pincode);
    final yearController = TextEditingController(text: _school.academicYear);
    bool isSaving = false;

    showAdaptiveEduStreakModal(
      context: context,
      isDark: true,
      title: 'Edit Operational Profile',
      icon: const Icon(Icons.settings_suggest_rounded, color: EduStreakTheme.neonCyan),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Notice on Protected vs Permitted
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C48),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EduStreakTheme.amberGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 16, color: EduStreakTheme.amberGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Protected attributes (School Code: ${_school.code}, Board: ${_school.type.displayName}) are locked to Central Admin governance.',
                            style: EduStreakTheme.fontCaption(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Official Contact Phone'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Official Contact Email'),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Campus Address'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: mandalController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Mandal / Block'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: pincodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'PIN Code'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: yearController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Operational Academic Year'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSaving = true);
                                try {
                                  final updates = {
                                    'contactPhone': phoneController.text.trim(),
                                    'contactEmail': emailController.text.trim(),
                                    'address': addressController.text.trim(),
                                    'mandal': mandalController.text.trim(),
                                    'pincode': pincodeController.text.trim(),
                                    'academicYear': yearController.text.trim(),
                                  };

                                  await _principalService.updateSchoolPermittedProfile(_school.id, updates);

                                  setState(() {
                                    _school = _school.copyWith(
                                      contactPhone: updates['contactPhone'],
                                      contactEmail: updates['contactEmail'],
                                      address: updates['address'],
                                      mandal: updates['mandal'],
                                      pincode: updates['pincode'],
                                      academicYear: updates['academicYear'],
                                    );
                                  });

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ School operational profile updated successfully!'),
                                        backgroundColor: EduStreakTheme.emeraldGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: EduStreakTheme.rosePink),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                        child: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Operational Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
