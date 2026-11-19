import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:edustreak/models/chat_model.dart';
import 'package:edustreak/models/message_model.dart';
import 'package:edustreak/models/user_model.dart';
import 'package:edustreak/providers/user_provider.dart';
import 'package:edustreak/widgets/portal_sidebar.dart';
import 'package:edustreak/services/realtime_chat_service.dart';

void main() {
  group('Real-Time Messaging Extended Model & Feature Tests', () {
    test('ChatModel typing indicators state tracking', () {
      final chat = ChatModel(
        id: 'chat_01',
        participants: ['u1', 'u2'],
        type: 'student_teacher',
        lastMessage: 'Hello',
        lastUpdated: DateTime.now(),
        typingUsers: {
          'u1': true,
          'u2': false,
        },
      );

      expect(chat.isUserTyping('u1'), isTrue);
      expect(chat.isUserTyping('u2'), isFalse);
      expect(chat.isUserTyping('u3'), isFalse);

      final map = chat.toMap();
      expect(map['typingUsers'], isA<Map>());
      expect(map['typingUsers']['u1'], isTrue);

      final revived = ChatModel.fromMap(map, 'chat_01');
      expect(revived.isUserTyping('u1'), isTrue);
    });

    test('MessageModel deliveryStatus serialization', () {
      final msg = MessageModel(
        id: 'msg_99',
        chatId: 'chat_01',
        senderId: 'u1',
        senderRole: 'student',
        text: 'Testing delivery status',
        deliveryStatus: 'delivered',
        timestamp: DateTime.now(),
        read: false,
      );

      expect(msg.deliveryStatus, 'delivered');
      final map = msg.toMap();
      expect(map['deliveryStatus'], 'delivered');

      final revived = MessageModel.fromMap(map);
      expect(revived.deliveryStatus, 'delivered');

      final copied = revived.copyWith(deliveryStatus: 'read');
      expect(copied.deliveryStatus, 'read');
      expect(copied.text, 'Testing delivery status');
    });

    test('RealtimeChatService chatType exhaustive role matrix', () {
      final service = RealtimeChatService();

      expect(service.chatType('student', 'teacher'), 'student_teacher');
      expect(service.chatType('teacher', 'student'), 'student_teacher');

      expect(service.chatType('teacher', 'parent'), 'parent_teacher');
      expect(service.chatType('parent', 'teacher'), 'parent_teacher');

      expect(service.chatType('student', 'student'), 'student_student');

      expect(service.chatType('principal', 'teacher'), 'principal_teacher');
      expect(service.chatType('teacher', 'principal'), 'principal_teacher');

      expect(service.chatType('principal', 'parent'), 'parent_principal');
      expect(service.chatType('parent', 'principal'), 'parent_principal');

      expect(service.chatType('parent', 'student'), 'parent_student');
      expect(service.chatType('student', 'parent'), 'parent_student');

      expect(service.chatType('admin', 'principal'), 'admin_principal');
      expect(service.chatType('principal', 'admin'), 'admin_principal');

      expect(service.chatType('admin', 'teacher'), 'admin_direct');
      expect(service.chatType('admin', 'student'), 'admin_direct');
      expect(service.chatType('admin', 'parent'), 'admin_direct');
    });
  });

  group('PortalSidebar Dynamic Unread Messages Badge Tests', () {
    testWidgets('PortalSidebar renders Messages tab in Admin portal', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortalSidebar(
              portalType: 'admin',
              selectedIndex: 10,
              onItemSelected: (_) {},
              userName: 'System Administrator',
            ),
          ),
        ),
      );

      expect(find.text('Messages'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    testWidgets('PortalSidebar renders Messages tab in Student portal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortalSidebar(
              portalType: 'student',
              selectedIndex: 9,
              onItemSelected: (_) {},
              userName: 'Jaswanth',
            ),
          ),
        ),
      );

      expect(find.text('Messages'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    testWidgets('PortalSidebar renders Messages tab in Parent portal without mock badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortalSidebar(
              portalType: 'parent',
              selectedIndex: 6,
              onItemSelected: (_) {},
              userName: 'Parent User',
            ),
          ),
        ),
      );

      expect(find.text('Messages'), findsOneWidget);
      // Ensure the old mock '3' badge on homework is gone
      expect(find.text('3'), findsNothing);
    });
  });
}
