import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/models/task_model.dart';
import 'package:edustreak/providers/user_provider.dart';
import 'package:edustreak/screens/student/widgets/practice_challenge_session_dialog.dart';

void main() {
  final testStudent = UserModel(
    id: 'student_jaswanth_01',
    name: 'Jaswanth Reddy',
    email: 'jaswanth@school.gov.in',
    role: 'student',
    classId: 'class_8a',
    grade: '8',
    section: 'A',
    rollNumber: '14',
    schoolId: 'school_ap_01',
    xp: 1450,
    spendablePoints: 1200,
    level: 3,
    streak: 7,
  );

  Widget createHarness(Widget child) {
    return ChangeNotifierProvider<UserProvider>(
      create: (_) {
        final p = UserProvider();
        p.setUser(testStudent);
        return p;
      },
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('1. Practice Challenge Session Dialog Tests', () {
    testWidgets('Renders challenge interface with timer, question, options and progress', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          const PracticeChallengeSessionDialog(
            studentId: 'student_jaswanth_01',
            studentName: 'Jaswanth Reddy',
            classId: 'class_8a',
            challengeTitle: 'Daily Practice Challenge',
            subject: 'Mixed Quiz',
            totalQuestions: 5,
            xpReward: 50,
            enableTimer: false,
          ),
        ),
      );

      // Settle loading questions
      await tester.pumpAndSettle();

      // Check header and title
      expect(find.text('Daily Practice Challenge'), findsOneWidget);
      expect(find.textContaining('Question 1 of'), findsOneWidget);

      // Check that options are rendered
      expect(find.byKey(const Key('challenge_next_button')), findsOneWidget);
      expect(find.byKey(const Key('challenge_prev_button')), findsOneWidget);

      // Select an option
      await tester.tap(find.byKey(const Key('challenge_option_0')));
      await tester.pumpAndSettle();

      // Tap Next to advance
      await tester.tap(find.byKey(const Key('challenge_next_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Question 2 of'), findsOneWidget);
    });

    testWidgets('Full challenge flow: answers questions, submits, calculates score and explanations', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createHarness(
          const PracticeChallengeSessionDialog(
            studentId: 'student_jaswanth_01',
            studentName: 'Jaswanth Reddy',
            classId: 'class_8a',
            challengeTitle: 'Daily Practice Challenge',
            subject: 'Mixed Quiz',
            totalQuestions: 2,
            xpReward: 50,
            enableTimer: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Question 1: Select option
      await tester.tap(find.byKey(const Key('challenge_option_0')));
      await tester.pumpAndSettle();

      // Next
      await tester.tap(find.byKey(const Key('challenge_next_button')));
      await tester.pumpAndSettle();

      // Question 2: Select option
      await tester.tap(find.byKey(const Key('challenge_option_0')));
      await tester.pumpAndSettle();

      // On last question, button says "Submit Challenge"
      expect(find.byKey(const Key('challenge_submit_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('challenge_submit_button')));
      await tester.pumpAndSettle();

      // Results screen should be visible with score and explanations
      expect(find.textContaining('Score:'), findsOneWidget);
      expect(find.textContaining('XP Earned'), findsOneWidget);
      expect(find.text('Question Breakdown & Solutions:'), findsOneWidget);
      expect(find.text('Return to Practice Arena'), findsOneWidget);
    });
  });

  group('2. Multi-Viewport Responsive Tests (0 RenderFlex Overflows)', () {
    final viewports = <String, Size>{
      'Compact Mobile (320x568)': const Size(320, 568),
      'Standard Mobile (360x800)': const Size(360, 800),
      'Large Mobile (412x915)': const Size(412, 915),
      'Tablet (800x1280)': const Size(800, 1280),
      'Laptop (1366x768)': const Size(1366, 768),
      'Desktop (1920x1080)': const Size(1920, 1080),
    };

    for (final entry in viewports.entries) {
      testWidgets('Practice challenge layout renders without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createHarness(
            const PracticeChallengeSessionDialog(
              studentId: 'student_jaswanth_01',
              studentName: 'Jaswanth Reddy',
              classId: 'class_8a',
              challengeTitle: 'Daily Practice Challenge',
              subject: 'Mixed Quiz',
              totalQuestions: 5,
              xpReward: 50,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Daily Practice Challenge'), findsOneWidget);
      });
    }
  });
}
