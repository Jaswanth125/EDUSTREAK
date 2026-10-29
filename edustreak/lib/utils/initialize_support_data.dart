import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to initialize Help & Support data in Firestore
/// Run this once to set up the support_info collection
Future<void> initializeSupportData() async {
  final firestore = FirebaseFirestore.instance;

  try {
    // 1. User Guide
    await firestore.collection('support_info').doc('user_guide').set({
      'title': 'User Guide',
      'content': '''Welcome to EduStreak! This app helps you track your child's academic performance, attendance, and rewards.

**Key Features:**
• **Child Progress**: View your child's attendance, badges, XP, and streaks
• **Leaderboard**: See how your child ranks among classmates
• **Messages**: Communicate directly with your child's teachers
• **Profile**: Manage your account settings and preferences

**Getting Started:**
1. Navigate through tabs using the bottom navigation bar
2. View your child's progress in the "Child Progress" tab
3. Check the leaderboard to see rankings
4. Use Messages to contact teachers
5. Update your profile in the Profile tab

**Tips:**
• Badges are awarded automatically when your child completes tasks
• XP points are earned through homework completion and attendance
• Streaks are maintained by daily logins and task completion
• Contact support through the Help & Support section if you need assistance''',
    });

    // 2. FAQs
    await firestore.collection('support_info').doc('faqs').set({
      'title': 'FAQs',
      'faqs': [
        {
          'question': 'How can I see my child\'s homework?',
          'answer': 'Go to the Child Progress tab to view your child\'s academic activities. Homework assignments and their status will be displayed there. You can also check with your child\'s teacher through the Messages tab.',
        },
        {
          'question': 'How do I chat with my child\'s teacher?',
          'answer': 'Tap the Messages tab at the bottom navigation bar. You can start a conversation with your child\'s class teacher from there. All messages are real-time and secure.',
        },
        {
          'question': 'How can I update my contact details?',
          'answer': 'Go to the Profile tab → Edit Profile → Update your contact information and save changes. Your updated information will be synced immediately.',
        },
        {
          'question': 'How do badges work?',
          'answer': 'Badges are awarded automatically when your child completes certain achievements like maintaining perfect attendance, completing homework assignments, or maintaining streaks. You can view all earned badges in the Child Progress tab.',
        },
        {
          'question': 'What are XP points?',
          'answer': 'XP (Experience Points) are earned when your child completes homework, maintains attendance, or achieves milestones. These points contribute to leveling up and unlocking rewards.',
        },
        {
          'question': 'How do streaks work?',
          'answer': 'Streaks are maintained by consistent daily logins and task completion. The longer the streak, the more rewards your child can earn. Streaks reset if a day is missed.',
        },
        {
          'question': 'Can I see my child\'s grades?',
          'answer': 'Yes! Once teachers grade assignments, you can view the grades and feedback in the Child Progress tab. You\'ll also receive notifications when new grades are posted.',
        },
        {
          'question': 'How do I contact support?',
          'answer': 'Go to Profile → Help & Support → Contact Support tab. You\'ll find contact information for our support team members. You can call them directly using the call button.',
        },
      ],
    });

    // 3. Contact Support
    await firestore.collection('support_info').doc('contact_support').set({
      'title': 'Contact Support',
      'contacts': [
        {
          'name': 'K. Jaswanth',
          'phone': '9985145125',
        },
        {
          'name': 'K. Jaswanth Pavan Kumar',
          'phone': '9581214074',
        },
        {
          'name': 'D. Tejesh',
          'phone': '7780159328',
        },
        {
          'name': 'S. Sohith',
          'phone': '8309507529',
        },
      ],
    });

    print('✅ Support data initialized successfully!');
  } catch (e) {
    print('❌ Error initializing support data: $e');
    rethrow;
  }
}

