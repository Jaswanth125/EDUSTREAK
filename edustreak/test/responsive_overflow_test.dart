import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edustreak/utils/edustreak_theme.dart';
import 'package:edustreak/widgets/portal_header.dart';
import 'package:edustreak/widgets/responsive/responsive_scaffold.dart';
import 'package:edustreak/widgets/responsive/responsive_bottom_nav.dart';
import 'package:edustreak/widgets/responsive/responsive_dialog.dart';
import 'package:edustreak/widgets/edustreak_illustrations.dart';
import 'package:provider/provider.dart';
import 'package:edustreak/providers/user_provider.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/screens/student/student_profile_dialog.dart';
import 'package:edustreak/screens/auth/login_screen.dart';
import 'package:edustreak/screens/auth/signup_screen.dart';
import 'package:edustreak/screens/auth/principal_invitation_screen.dart';
import 'package:edustreak/widgets/responsive/registration_step_indicator.dart';
import 'package:edustreak/screens/teacher/teacher_ai_teaching_hub_tab.dart';
import 'package:edustreak/screens/teacher/teacher_assessments_tab.dart';
import 'package:edustreak/screens/teacher/learning_resources_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_dashboard_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_school_overview_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_announcements_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_students_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_teachers_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_academics_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_approvals_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_attendance_tab.dart';
import 'package:edustreak/screens/principal/tabs/principal_reports_tab.dart';
import 'package:edustreak/models/assessment_model.dart';
import 'package:edustreak/models/resource_model.dart';
import 'package:edustreak/models/school_model.dart';
import 'package:edustreak/models/task_model.dart';
import 'package:edustreak/screens/parent/parent_portal_screen.dart';
import 'package:edustreak/screens/parent/parent_profile_dialog.dart';
import 'package:edustreak/screens/admin/principal_management_screen.dart';
import 'package:edustreak/screens/admin/parent_directory_screen.dart';
import 'package:edustreak/screens/admin/teacher_directory_screen.dart';
import 'package:edustreak/screens/admin/student_directory_screen.dart';
import 'package:edustreak/screens/admin/academic_monitoring_screen.dart';
import 'package:edustreak/screens/admin/attendance_monitoring_screen.dart';
import 'package:edustreak/screens/admin/academic_structure_screen.dart';

void main() {
  const viewports = [
    Size(320, 568),   // 1. Small Mobile (e.g. iPhone SE 1st gen / ultra-compact)
    Size(360, 800),   // 2. Standard Mobile (Standard Android 360dp)
    Size(412, 915),   // 3. Large Mobile (Google Pixel 7/8, Samsung S23/S24)
    Size(430, 932),   // 4. Tall Mobile (iPhone 14/15/16 Pro Max)
    Size(600, 960),   // 5. Small Tablet (7-8" Android tablet / iPad Mini portrait)
    Size(800, 1280),  // 6. Large Tablet (10-11" tablet / iPad Air/Pro portrait)
    Size(1366, 768),  // 7. Laptop (Standard Chromebook / Budget Laptop)
    Size(1920, 1080), // 8. Desktop / TV (Full HD Desktop / TV Presentation)
  ];

  group('EduStreak Multi-Device Responsive Header Tests (Zero Overflows)', () {
    for (final size in viewports) {
      testWidgets('Admin Portal Header at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isCompact = size.width < 600;

        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('FULL FLUTTER ERROR:\n${details.toString()}');
          oldHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ResponsiveScaffold(
              portalType: 'admin',
              selectedIndex: 0,
              onItemSelected: (_) {},
              portalIcon: Icons.admin_panel_settings_rounded,
              headerTitle: 'Central Admin Portal',
              headerSubtitle: 'State Educational Operations • Unified Governance',
              contextPillText: 'All Schools',
              contextPillOptions: const ['All Schools', 'Government Only'],
              avatarWidget: isCompact
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E265C),
                          ),
                          child: const Center(child: Text('A', style: TextStyle(color: Colors.white))),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: EduStreakTheme.primaryViolet,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: const Text('Master Admin', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Container(width: 36, height: 36, color: Colors.blue),
                      ],
                    ),
              body: const Center(child: Text('Admin Content')),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Admin Header at ${size.width}x${size.height}');
      });

      testWidgets('Student Portal Header at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isNarrow = size.width < 450;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: ResponsiveScaffold(
              portalType: 'student',
              selectedIndex: 0,
              onItemSelected: (_) {},
              portalIcon: Icons.school_rounded,
              headerTitle: 'Student Portal',
              headerSubtitle: 'Class 8-A • Academic Excellence',
              contextPillText: 'Class 8-A',
              avatarWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: const Text('🔥 7', style: TextStyle(color: EduStreakTheme.streakOrange)),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Text('🪙 1450 XP'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  const CircleAvatar(radius: 16),
                ],
              ),
              body: const Center(child: Text('Student Content')),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Student Header at ${size.width}x${size.height}');
      });

      testWidgets('Teacher Portal Header at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isCompact = size.width < 500;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ResponsiveScaffold(
              portalType: 'teacher',
              selectedIndex: 0,
              onItemSelected: (_) {},
              portalIcon: Icons.co_present_rounded,
              headerTitle: 'Teacher Portal',
              headerSubtitle: 'Faculty Management • Class 8-A',
              contextPillText: 'Class 8-A',
              avatarWidget: isCompact
                  ? Stack(
                      children: [
                        const CircleAvatar(radius: 17),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(width: 9, height: 9, color: Colors.green),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          child: const Text('Live: Class 8-A'),
                        ),
                        const SizedBox(width: 10),
                        const CircleAvatar(radius: 17),
                      ],
                    ),
              body: const Center(child: Text('Teacher Content')),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Teacher Header at ${size.width}x${size.height}');
      });

      testWidgets('Parent Portal Header at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isCompact = size.width < 500;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: ResponsiveScaffold(
              portalType: 'parent',
              selectedIndex: 0,
              onItemSelected: (_) {},
              portalIcon: Icons.family_restroom_rounded,
              headerTitle: 'Parent Portal',
              headerSubtitle: 'Guardian Dashboard • Student Overview',
              contextPillText: 'Akash (Class 8-A)',
              avatarWidget: isCompact
                  ? Stack(
                      children: [
                        const CircleAvatar(radius: 17),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(width: 9, height: 9, color: Colors.green),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          child: const Text('Linked & Verified'),
                        ),
                        const SizedBox(width: 10),
                        const CircleAvatar(radius: 17),
                      ],
                    ),
              body: const Center(child: Text('Parent Content')),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Parent Header at ${size.width}x${size.height}');
      });

      testWidgets('Principal Portal Header at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isCompact = size.width < 900;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: ResponsiveScaffold(
              portalType: 'principal',
              selectedIndex: 0,
              onItemSelected: (_) {},
              portalIcon: Icons.account_balance_rounded,
              headerTitle: 'Principal Portal',
              headerSubtitle: 'Z.P. High School • Dr. Sudhir Sharma',
              contextPillText: '2024-2025 • Active',
              avatarWidget: isCompact
                  ? Stack(
                      children: [
                        const CircleAvatar(radius: 17),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(width: 9, height: 9, color: Colors.green),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          child: const Text('AP-KRI-042 • Principal'),
                        ),
                        const SizedBox(width: 10),
                        const CircleAvatar(radius: 17),
                      ],
                    ),
              body: const Center(child: Text('Principal Content')),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Principal Header at ${size.width}x${size.height}');
      });
    }
  });

  group('EduStreak Responsive Cards & Segmented Controls (360px Narrow Mobile)', () {
    testWidgets('Schools by Type Card Stacks Vertically on 360px without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: EduStreakTheme.darkCardDecoration(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chart = const SizedBox(width: 130, height: 130, child: Placeholder());
                    final legends = Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(child: Text('Government Schools', overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            const Text('14 (56.0%)'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(child: Text('Private Autonomous Schools', overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            const Text('8 (32.0%)'),
                          ],
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 420) {
                      return Column(
                        children: [
                          Center(child: chart),
                          const SizedBox(height: 20),
                          legends,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        chart,
                        const SizedBox(width: 24),
                        Expanded(child: legends),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Schools by Type card at 360px');
    });

    testWidgets('Curriculum Management Card Header wraps without overflow at 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;
                  return isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.layers_rounded, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Curriculum Management',
                                    style: EduStreakTheme.fontHeading3(
                                      color: Colors.white,
                                      weight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {},
                                icon: const Text('Manage Standards'),
                                label: const Icon(Icons.arrow_forward_rounded, size: 14),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Curriculum Management',
                                      style: EduStreakTheme.fontHeading2(
                                        color: Colors.white,
                                        weight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Text('Manage Standards'),
                              label: const Icon(Icons.arrow_forward_rounded, size: 14),
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Curriculum Management Header at 360px');
    });

    testWidgets('Curriculum Builder Segmented Scope Selector scrolls smoothly at 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A42),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text('AP State Govt')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text('CBSE Central')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text('Private Schools')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Scope Selector at 360px');
    });

    testWidgets('QuestCastleCard with very long title wraps without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestCastleCard(
              questTitle: 'Weekly Dragon Slayer Trial with Extended Requirements and Multiple Steps',
              questSubtitle: 'Advanced Mathematics and Linear Geometry Applications',
              pendingTasks: [
                'Complete Chapter 4 Linear Equations Quiz with >80% Accuracy on First Attempt',
                'Submit Homework Assignment Part B before Friday 5:00 PM IST',
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in QuestCastleCard check item');
    });

    testWidgets('ResponsiveBottomNav renders cleanly across all 5 portals at 320px & 360px', (tester) async {
      for (final width in [320.0, 360.0]) {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final portal in ['admin', 'student', 'teacher', 'parent', 'principal']) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                bottomNavigationBar: ResponsiveBottomNav(
                  portalType: portal,
                  selectedIndex: 0,
                  onItemSelected: (_) {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in ResponsiveBottomNav for $portal at ${width}px');
        }
      }
    });

    testWidgets('StreakFlameCard renders with zero overflows in constrained widths (120px to 160px)', (tester) async {
      for (final width in [120.0, 135.0, 150.0, 160.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: const StreakFlameCard(streakDays: 12),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in StreakFlameCard at width $width');
      }
    });

    testWidgets('Student Portal Mobile Stats Row renders without overflow at 320px, 360px, 375px', (tester) async {
      for (final width in [320.0, 360.0, 375.0, 390.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: StreakFlameCard(streakDays: 12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: LevelXpProgressRing(
                              level: 7,
                              rankTitle: 'Scholar',
                              currentXp: 2450,
                              targetXp: 3000,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Mobile Stats Row at width $width');
      }
    });

    testWidgets('Parent Portal Dark Theme Cards render with zero overflow across viewports', (tester) async {
      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              backgroundColor: EduStreakTheme.studentDarkBg,
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Child Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: EduStreakTheme.studentDarkCardDecoration(),
                        child: Row(
                          children: [
                            const AkashStudentAvatar(size: 54),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Akash Sharma',
                                        style: EduStreakTheme.fontHeading1(color: Colors.white, weight: FontWeight.w800),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: EduStreakTheme.studentDarkCardSub,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: EduStreakTheme.studentDarkBorder),
                                        ),
                                        child: Text(
                                          'Class 10 • Section A',
                                          style: EduStreakTheme.fontLabel(color: EduStreakTheme.studentDarkHighlight, weight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'School Code: SCH-001 • Roll #12',
                                    style: EduStreakTheme.fontBody(color: EduStreakTheme.studentDarkTextMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Growth Insight Callout
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: EduStreakTheme.studentDarkCardSub,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EduStreakTheme.emeraldGreen.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_graph_rounded, color: EduStreakTheme.emeraldGreen, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '12-Day Learning Streak Active',
                                    style: EduStreakTheme.fontHeading3(color: Colors.white, weight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Akash has maintained a consistent learning habit.',
                                    style: EduStreakTheme.fontCaption(color: EduStreakTheme.studentDarkHighlight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in Parent Portal Dark Cards at ${size.width}x${size.height}');
      }
    });
  });

  group('EduStreak Multi-Viewport Screens & Modals Zero Overflow Verification', () {
    testWidgets('LoginScreen renders all 5 roles and switches to Admin without overflow across all 8 viewports', (tester) async {
      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in LoginScreen at ${size.width}x${size.height}');

        // Verify Admin role is present and clickable
        final adminFinder = find.text('Admin');
        expect(adminFinder, findsWidgets);

        await tester.tap(adminFinder.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow after switching to Admin role at ${size.width}x${size.height}');
        expect(find.text('Central Admin Operations'), findsOneWidget);
      }
    });

    testWidgets('ResponsiveDialog bottom sheet with multiple action buttons wraps cleanly at 320x568', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showAdaptiveEduStreakModal<void>(
                    context: ctx,
                    title: 'Transfer Student Records',
                    actions: [
                      TextButton(onPressed: () {}, child: const Text('Cancel Request')),
                      ElevatedButton(onPressed: () {}, child: const Text('Confirm Transfer & Reassign')),
                    ],
                    builder: (sheetCtx) => const Text('Transfer Content Details'),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in ResponsiveDialog actions at 320x568');
      expect(find.text('Confirm Transfer & Reassign'), findsOneWidget);
    });

    testWidgets('PortalHeader with long dropdown text does not overflow at 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PortalHeader(
              title: 'Central Admin Portal',
              subtitle: 'State Educational Operations • Governance',
              portalIcon: Icons.admin_panel_settings_rounded,
              contextPillText: 'All Government & Autonomous Institutions',
              contextPillOptions: const ['All Government & Autonomous Institutions', 'Private Only'],
              onDevSwitchPortal: (_) {},
              isDark: true,
              avatarWidget: const CircleAvatar(radius: 16),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in PortalHeader with long dropdown text at 320px');
    });

    testWidgets('StudentProfileDialog renders with zero overflows at 320x568 and 360x800', (tester) async {
      final testStudent = UserModel(
        id: 'test_student_1',
        name: 'Alex Johnson',
        email: 'alex@edustreak.com',
        role: 'student',
        schoolCode: 'AP-KRI-042',
        rollNumber: '101',
        grade: '8',
        section: 'A',
        isActive: true,
        status: 'active',
        streak: 15,
        streakCount: 15,
        highestStreak: 18,
        xp: 1450,
        spendablePoints: 850,
        level: 4,
        badges: const ['badge_streak_7', 'badge_quiz_master'],
        purchasedItems: const ['avatar_1'],
        redeemedAvatars: const ['avatar_1'],
        childIds: const [],
        assignedSubjects: const [],
      );

      for (final size in [const Size(320, 568), const Size(360, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('STUDENT_PROFILE_OVERFLOW:\n${details.toString()}');
          oldHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      StudentProfileDialog.show(context, testStudent);
                    },
                    child: const Text('Open Profile'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Profile'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in StudentProfileDialog at ${size.width}x${size.height}');
        expect(find.text('Student Profile'), findsOneWidget);
        expect(find.text('Alex Johnson'), findsWidgets);

        // Tap Edit Profile to verify editing form does not overflow
        final editButton = find.text('Edit Profile');
        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'RenderFlex overflow in StudentProfileDialog edit mode at ${size.width}x${size.height}');
        }

        // Close dialog for next size
        final closeButton = find.byIcon(Icons.close_rounded);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  group('Registration Flow Responsive Zero-Overflow Tests', () {
    testWidgets('RegistrationStepIndicator across all 8 viewports without overflow', (tester) async {
      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (int step = 0; step < 4; step++) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: Center(
                  child: RegistrationStepIndicator(
                    currentStep: step,
                    isDark: true,
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow in RegistrationStepIndicator at step $step on ${size.width}x${size.height}',
          );
        }
      }
    });

    testWidgets('PrincipalInvitationScreen across all 8 viewports without overflow', (tester) async {
      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const PrincipalInvitationScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow in PrincipalInvitationScreen at ${size.width}x${size.height}',
        );
        expect(find.text('Accept Principal Invitation'), findsOneWidget);
        expect(find.text('Verify Invitation Code'), findsOneWidget);
      }
    });

    testWidgets('SignUpScreen Landing View across all 8 viewports without overflow', (tester) async {
      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const SignUpScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow in SignUpScreen landing view at ${size.width}x${size.height}',
        );
        expect(find.text('Join EduStreak'), findsWidgets);
        expect(find.text('Student Registration'), findsWidgets);
        expect(find.text('Faculty / Teacher Registration'), findsWidgets);
        expect(find.text('Parent & Guardian Portal'), findsWidgets);
      }
    });

    testWidgets('SignUpScreen Student 4-Step Wizard View across all 8 viewports without overflow', (tester) async {
      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider(),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const SignUpScreen(initialRoleIndex: 0),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow in SignUpScreen Student Wizard at ${size.width}x${size.height}',
        );
        expect(find.text('Student School Verification'), findsWidgets);
        expect(find.text('Verify Student Record'), findsWidgets);
      }
    });

    testWidgets('TeacherAiTeachingHubTab renders without crash or overflow with empty classIds across viewports', (tester) async {
      final emptyTeacher = UserModel(
        id: 't_empty',
        name: 'Empty Teacher',
        email: 't_empty@school.edu',
        role: 'teacher',
        classIds: [],
        assignedSubjects: [],
      );

      for (final size in [const Size(320, 568), const Size(360, 800), const Size(1024, 768)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: TeacherAiTeachingHubTab(user: emptyTeacher),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Crash or overflow in TeacherAiTeachingHubTab at ${size.width}x${size.height}');
        expect(find.text('AI Teaching Hub'), findsWidgets);
        expect(find.text('Lesson Plan Generator'), findsWidgets);
        expect(find.text('Student Learning Insights'), findsWidgets);
      }
    });

    testWidgets('TeacherAssessmentsTab renders without overflow across viewports', (tester) async {
      final teacher = UserModel(
        id: 't_1',
        name: 'Teacher 1',
        email: 't1@school.edu',
        role: 'teacher',
        classIds: ['Class 8A', 'Class 8B'],
        assignedSubjects: ['Science'],
      );

      for (final size in [const Size(320, 568), const Size(360, 800), const Size(1366, 768)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: TeacherAssessmentsTab(
                user: teacher,
                assessmentsStream: Stream.value(<AssessmentModel>[]),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in TeacherAssessmentsTab at ${size.width}x${size.height}');
        expect(find.text('Assessments & Tests'), findsWidgets);
        expect(find.text('Create Assessment'), findsWidgets);
      }
    });

    testWidgets('LearningResourcesTab renders without overflow across mobile and desktop viewports', (tester) async {
      final teacher = UserModel(
        id: 't_1',
        name: 'Teacher 1',
        email: 't1@school.edu',
        role: 'teacher',
        classIds: ['Class 8A'],
        assignedSubjects: ['Science'],
      );

      for (final size in [const Size(320, 568), const Size(360, 800), const Size(412, 915), const Size(1366, 768)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: LearningResourcesTab(
                user: teacher,
                resourcesStream: Stream.value(<ResourceModel>[]),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in LearningResourcesTab at ${size.width}x${size.height}');
        expect(find.text('Learning Resource Library'), findsWidgets);
        expect(find.text('Upload Resource'), findsWidgets);
      }
    });

    testWidgets('PrincipalDashboardTab renders without overflow across mobile viewports', (tester) async {
      final mockSchool = SchoolModel(
        id: 'sch_1',
        name: 'Z.P. High School, Kankipadu',
        code: 'AP-KRI-042',
        district: 'Krishna',
        state: 'Andhra Pradesh',
        mandal: 'Kankipadu',
        address: 'Main Road',
        pincode: '521151',
        type: SchoolType.government,
        establishedDate: DateTime(2024, 1, 1),
        curriculumTemplateId: 'ap_state_board_scert',
        affiliationNumber: 'SCERT-AP-2024-KRI-042',
        academicYear: '2024-2025',
        totalStudents: 620,
        totalTeachers: 28,
        status: 'active',
      );
      final mockPrincipal = UserModel(
        id: 'p_1',
        name: 'Dr. David Smith',
        email: 'principal@school.edu',
        role: 'principal',
        schoolId: 'sch_1',
      );

      for (final size in [const Size(320, 568), const Size(360, 800), const Size(390, 844), const Size(1366, 768)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalDashboardTab(
                school: mockSchool,
                principal: mockPrincipal,
                onNavigateToTab: (_) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalDashboardTab at ${size.width}x${size.height}');
        expect(find.text('Class-wise Academic Performance'), findsWidgets);
        expect(find.text('At-Risk Students Requiring Intervention'), findsWidgets);
      }
    });

    testWidgets('PrincipalSchoolOverviewTab renders without overflow across mobile viewports', (tester) async {
      final mockSchool = SchoolModel(
        id: 'sch_1',
        name: 'Z.P. High School, Kankipadu',
        code: 'AP-KRI-042',
        district: 'Krishna',
        state: 'Andhra Pradesh',
        mandal: 'Kankipadu',
        address: 'Main Road',
        pincode: '521151',
        type: SchoolType.government,
        establishedDate: DateTime(2024, 1, 1),
        curriculumTemplateId: 'ap_state_board_scert',
        affiliationNumber: 'SCERT-AP-2024-KRI-042',
        academicYear: '2024-2025',
        totalStudents: 620,
        totalTeachers: 28,
        status: 'active',
      );
      final mockPrincipal = UserModel(
        id: 'p_1',
        name: 'Dr. David Smith',
        email: 'principal@school.edu',
        role: 'principal',
        schoolId: 'sch_1',
      );

      for (final size in [const Size(320, 568), const Size(360, 800), const Size(390, 844), const Size(1366, 768)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('FULL OVERFLOW ERROR in OverviewTab:\n${details.toString()}');
          oldHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalSchoolOverviewTab(
                school: mockSchool,
                principal: mockPrincipal,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalSchoolOverviewTab at ${size.width}x${size.height}');
        expect(find.text('Z.P. High School, Kankipadu'), findsWidgets);
        expect(find.text('Edit Settings'), findsWidgets);
      }
    });

    testWidgets('Principal Portal Tabs render without overflow across mobile and desktop viewports', (tester) async {
      final mockSchool = SchoolModel(
        id: 'sch_1',
        name: 'Z.P. High School, Kankipadu',
        code: 'AP-KRI-042',
        district: 'Krishna',
        state: 'Andhra Pradesh',
        mandal: 'Kankipadu',
        address: 'Main Road',
        pincode: '521151',
        type: SchoolType.government,
        establishedDate: DateTime(2024, 1, 1),
        curriculumTemplateId: 'ap_state_board_scert',
        affiliationNumber: 'SCERT-AP-2024-KRI-042',
        academicYear: '2024-2025',
        totalStudents: 620,
        totalTeachers: 28,
        status: 'active',
      );
      final mockPrincipal = UserModel(
        id: 'p_1',
        name: 'Dr. David Smith',
        email: 'principal@school.edu',
        role: 'principal',
        schoolId: 'sch_1',
      );

      final testViewports = [
        const Size(320, 568),
        const Size(360, 800),
        const Size(412, 915),
        const Size(800, 1280),
        const Size(1366, 768),
      ];

      for (final size in testViewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Announcements Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalAnnouncementsTab(school: mockSchool, principal: mockPrincipal),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalAnnouncementsTab at ${size.width}x${size.height}');

        // 2. Students Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalStudentsTab(school: mockSchool),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalStudentsTab at ${size.width}x${size.height}');

        // 3. Teachers Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalTeachersTab(school: mockSchool),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalTeachersTab at ${size.width}x${size.height}');

        // 4. Academics Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalAcademicsTab(school: mockSchool),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalAcademicsTab at ${size.width}x${size.height}');

        // 5. Approvals Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalApprovalsTab(school: mockSchool, principal: mockPrincipal),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalApprovalsTab at ${size.width}x${size.height}');

        // 6. Attendance Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalAttendanceTab(school: mockSchool),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalAttendanceTab at ${size.width}x${size.height}');

        // 7. Reports Tab
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: PrincipalReportsTab(school: mockSchool),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalReportsTab at ${size.width}x${size.height}');
      }
    });

    testWidgets('ParentPortalScreen renders all tabs without overflow across viewports', (tester) async {
      final mockParent = UserModel(
        id: 'parent_1',
        name: 'Srinivasa Rao',
        email: 'parent@edustreak.edu',
        role: 'parent',
        schoolId: 'sch_1',
        schoolCode: 'AP-KRI-042',
        childIds: ['child_1'],
      );

      final mockChild = UserModel(
        id: 'child_1',
        name: 'Akash Kumar',
        email: 'akash@edustreak.edu',
        role: 'student',
        schoolId: 'sch_1',
        schoolCode: 'AP-KRI-042',
        grade: '8',
        section: 'A',
        rollNumber: '24',
        admissionNumber: 'ADM-2024-089',
        academicYear: '2026-2027',
        streakCount: 14,
        xp: 2850,
        level: 7,
      );

      final mockTasks = [
        TaskModel(
          id: 'task_1',
          classId: 'Class 8A',
          title: 'Physics Force & Pressure Lab Problem Set',
          description: 'Solve textbook exercises 1 to 10 with free-body diagrams.',
          subject: 'Physics',
          assignedBy: 't_1',
          assignedByName: 'Ms. Kavya Rao',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          createdAt: DateTime.now(),
          assignedTo: ['child_1'],
          maxMarks: 25,
          marks: {'child_1': 23.0},
          submissions: {'child_1': 'submitted'},
        ),
        TaskModel(
          id: 'task_2',
          classId: 'Class 8A',
          title: 'Mathematics Polynomial Factorization Worksheet',
          description: 'Complete algebraic expressions factorization.',
          subject: 'Mathematics',
          assignedBy: 't_2',
          assignedByName: 'Mr. Rajesh Sharma',
          dueDate: DateTime.now().add(const Duration(hours: 12)),
          createdAt: DateTime.now(),
          assignedTo: ['child_1'],
          maxMarks: 50,
        ),
      ];

      final mockAssessments = [
        AssessmentModel(
          id: 'asm_1',
          schoolId: 'sch_1',
          classId: 'Class 8A',
          subject: 'Science',
          title: 'Periodic Assessment 1 - Mechanics',
          type: 'unit_test',
          scheduledDate: DateTime.now().subtract(const Duration(days: 5)),
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          createdBy: 't_1',
          createdByName: 'Ms. Kavya Rao',
          totalMarks: 25,
          scores: {'child_1': 22.5},
          feedback: {'child_1': 'Excellent conceptual depth and diagram clarity.'},
        ),
      ];

      final userProvider = UserProvider();
      userProvider.setUser(mockParent);

      for (final size in [
        const Size(320, 568),
        const Size(360, 800),
        const Size(390, 844),
        const Size(768, 1024),
        const Size(1366, 768),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('FULL OVERFLOW ERROR in ParentPortalScreen:\n${details.toString()}');
          oldHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: ParentPortalScreen(
                key: ValueKey('parent_portal_${size.width}'),
                childrenStream: Stream.value([mockChild]).asBroadcastStream(),
                tasksStream: Stream.value(mockTasks).asBroadcastStream(),
                assessmentsStream: Stream.value(mockAssessments).asBroadcastStream(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in ParentPortal Dashboard at ${size.width}x${size.height}');
        expect(find.text('Akash Kumar'), findsWidgets);
        expect(find.text('Parent Portal'), findsWidgets);
      }
    });

    testWidgets('ParentProfileDialog renders cleanly without overflow on 320x568 and 360x800', (tester) async {
      final mockParent = UserModel(
        id: 'parent_1',
        name: 'Srinivasa Rao',
        email: 'parent@edustreak.edu',
        role: 'parent',
        schoolId: 'sch_1',
        schoolCode: 'AP-KRI-042',
        childIds: ['child_1'],
      );

      final mockChild = UserModel(
        id: 'child_1',
        name: 'Akash Kumar',
        email: 'akash@edustreak.edu',
        role: 'student',
        schoolId: 'sch_1',
        grade: '8',
        section: 'A',
      );

      for (final size in [const Size(320, 568), const Size(360, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ParentProfileDialog(
                key: ValueKey('dialog_${size.width}'),
                user: mockParent,
                selectedChild: mockChild,
                children: [mockChild],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in ParentProfileDialog at ${size.width}x${size.height}');
        expect(find.text('Srinivasa Rao'), findsWidgets);
        expect(find.text('Verified Parent Account'), findsWidgets);
        expect(find.text('Linked Children'), findsWidgets);

        // Switch to Security tab
        await tester.tap(find.text('Security'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in ParentProfileDialog Security tab');
        expect(find.text('Change Password'), findsWidgets);

        // Switch to Settings tab
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in ParentProfileDialog Settings tab');
        expect(find.text('App Preferences'), findsWidgets);
      }
    });
  });

  group('EduStreak Central Admin Responsive Tests (Zero Overflows)', () {
    const adminTestViewports = [
      Size(320, 568),   // Small Mobile (iPhone SE 1st gen)
      Size(360, 800),   // Standard Android Mobile (User bug report target)
      Size(412, 915),   // Large Mobile (Pixel 7/8, Samsung S23/S24)
      Size(1920, 1080), // Desktop Full HD
    ];

    for (final size in adminTestViewports) {
      testWidgets('PrincipalManagementScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PrincipalManagementScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in PrincipalManagementScreen at ${size.width}x${size.height}');
      });

      testWidgets('ParentDirectoryScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParentDirectoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in ParentDirectoryScreen at ${size.width}x${size.height}');
      });

      testWidgets('TeacherDirectoryScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TeacherDirectoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in TeacherDirectoryScreen at ${size.width}x${size.height}');
      });

      testWidgets('StudentDirectoryScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StudentDirectoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in StudentDirectoryScreen at ${size.width}x${size.height}');
      });

      testWidgets('AcademicMonitoringScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AcademicMonitoringScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in AcademicMonitoringScreen at ${size.width}x${size.height}');
      });

      testWidgets('AttendanceMonitoringScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AttendanceMonitoringScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in AttendanceMonitoringScreen at ${size.width}x${size.height}');
      });

      testWidgets('AcademicStructureScreen at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AcademicStructureScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in AcademicStructureScreen at ${size.width}x${size.height}');
      });
    }
  });
}
