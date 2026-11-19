import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:edustreak/models/chat_model.dart';
import 'package:edustreak/models/message_model.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/providers/user_provider.dart';
import 'package:edustreak/services/realtime_chat_service.dart';
import 'package:edustreak/screens/chat/realtime_chat_list_screen.dart';
import 'package:edustreak/screens/chat/widgets/conversation_sidebar.dart';
import 'package:edustreak/screens/chat/widgets/chat_window_view.dart';
import 'package:edustreak/screens/chat/widgets/chat_info_panel.dart';
import 'package:edustreak/screens/chat/widgets/chat_message_composer.dart';
import 'package:edustreak/screens/chat/widgets/new_chat_dialog.dart';

void main() {
  final testUser = UserModel(
    id: 'user_student_01',
    name: 'Aarav Sharma',
    email: 'aarav@edustreak.com',
    role: 'student',
    classId: 'cls_10_a',
    grade: '10',
    section: 'A',
    schoolId: 'sch_ap_001',
  );

  final testChat = ChatModel(
    id: 'user_student_01_user_teacher_01',
    participants: ['user_student_01', 'user_teacher_01'],
    type: 'student_teacher',
    lastMessage: 'Here is the physics homework assignment',
    lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
    participantNames: {
      'user_student_01': 'Aarav Sharma',
      'user_teacher_01': 'Lakshmi Devi (Physics)',
    },
    participantRoles: {
      'user_student_01': 'student',
      'user_teacher_01': 'teacher',
    },
    unreadCounts: {
      'user_student_01': 2,
      'user_teacher_01': 0,
    },
    isPinned: true,
    isMuted: {
      'user_student_01': false,
    },
  );

  final testMessages = [
    MessageModel(
      id: 'msg_01',
      chatId: testChat.id,
      senderId: 'user_teacher_01',
      senderName: 'Lakshmi Devi',
      senderRole: 'teacher',
      text: 'Good morning Aarav, please review Chapter 4 optics before class tomorrow. నమస్కారం!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      read: true,
      reactions: {'👍': ['user_student_01']},
    ),
    MessageModel(
      id: 'msg_02',
      chatId: testChat.id,
      senderId: 'user_student_01',
      senderName: 'Aarav Sharma',
      senderRole: 'student',
      text: 'Sure Maam, I completed the ray diagrams yesterday. ధన్యవాదాలు!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      read: true,
      replyToId: 'msg_01',
      replyToText: 'Good morning Aarav, please review Chapter 4 optics before class tomorrow.',
      replyToSender: 'Lakshmi Devi',
    ),
    MessageModel(
      id: 'msg_03',
      chatId: testChat.id,
      senderId: 'user_teacher_01',
      senderName: 'Lakshmi Devi',
      senderRole: 'teacher',
      text: 'Excellent work!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      read: false,
      type: 'file',
      attachmentName: 'optics_diagrams_sample.pdf',
      attachmentSize: 420000,
    ),
  ];

  Widget createTestHarness(Widget child) {
    return ChangeNotifierProvider<UserProvider>(
      create: (_) {
        final provider = UserProvider();
        provider.setUser(testUser);
        return provider;
      },
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: child,
      ),
    );
  }

  group('EduStreak Messaging Architecture & Model Tests', () {
    test('ChatModel helper methods and unread resolution', () {
      expect(testChat.getOtherParticipantId('user_student_01'), 'user_teacher_01');
      expect(testChat.getOtherParticipantName('user_student_01'), 'Lakshmi Devi (Physics)');
      expect(testChat.getOtherParticipantRole('user_student_01'), 'teacher');
      expect(testChat.getUnreadCount('user_student_01'), 2);
      expect(testChat.getUnreadCount('user_teacher_01'), 0);
      expect(testChat.isPinned, isTrue);
      expect(testChat.isMutedFor('user_student_01'), isFalse);
    });

    test('MessageModel reaction and reply parsing', () {
      final msg = testMessages[0];
      expect(msg.reactions['👍']?.contains('user_student_01'), isTrue);
      expect(msg.isEdited, isFalse);
      expect(msg.isDeleted, isFalse);

      final replyMsg = testMessages[1];
      expect(replyMsg.replyToSender, 'Lakshmi Devi');
      expect(replyMsg.replyToText?.contains('Chapter 4'), isTrue);
    });

    test('RealtimeChatService chat ID sorting and type generation', () {
      final service = RealtimeChatService();
      final id1 = service.buildChatId('user_b', 'user_a');
      final id2 = service.buildChatId('user_a', 'user_b');
      expect(id1, 'user_a_user_b');
      expect(id2, 'user_a_user_b');

      expect(service.chatType('student', 'teacher'), 'student_teacher');
      expect(service.chatType('teacher', 'parent'), 'parent_teacher');
      expect(service.chatType('teacher', 'principal'), 'principal_teacher');
      expect(service.chatType('admin', 'teacher'), 'admin_direct');
    });
  });

  group('EduStreak Modular Messaging Widget Rendering', () {
    testWidgets('ChatMessageComposer renders with input and action buttons', (tester) async {
      await tester.pumpWidget(
        createTestHarness(
          Scaffold(
            body: ChatMessageComposer(
              chatId: testChat.id,
              replyToMessage: null,
              onCancelReply: () {},
              onSendMessage: ({
                required String text,
                String type = 'text',
                String? attachmentUrl,
                String? attachmentName,
                int? attachmentSize,
              }) {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
    });

    testWidgets('ChatInfoPanel renders profile card and shared media headers', (tester) async {
      await tester.pumpWidget(
        createTestHarness(
          Scaffold(
            body: ChatInfoPanel(
              currentUser: testUser,
              chat: testChat,
              messages: testMessages,
            ),
          ),
        ),
      );

      expect(find.text('Chat Details'), findsOneWidget);
      expect(find.text('Lakshmi Devi (Physics)'), findsOneWidget);
      expect(find.text('TEACHER'), findsOneWidget);
      expect(find.text('Shared Documents (1)'), findsOneWidget);
    });

    testWidgets('NewChatDialog renders dark container with search and filter tabs', (tester) async {
      await tester.pumpWidget(
        createTestHarness(
          NewChatDialog(currentUser: testUser),
        ),
      );

      expect(find.text('New Conversation'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('EduStreak Messaging Responsive Viewport Suite (Zero Overflows)', () {
    const viewports = [
      Size(320, 568),   // Small Mobile (iPhone SE)
      Size(360, 800),   // Standard Mobile
      Size(412, 915),   // Large Mobile (Pixel 7/8)
      Size(800, 1280),  // Tablet
      Size(1366, 768),  // Laptop
      Size(1920, 1080), // Desktop Full HD
    ];

    for (final size in viewports) {
      testWidgets('RealtimeChatListScreen at ${size.width.toInt()}x${size.height.toInt()} with zero overflows', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestHarness(
            const RealtimeChatListScreen(showAppBar: true),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
      });

      testWidgets('ChatWindowView at ${size.width.toInt()}x${size.height.toInt()} with zero overflows', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestHarness(
            Scaffold(
              body: ChatWindowView(
                currentUser: testUser,
                chat: testChat,
                isMobile: size.width < 768,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
