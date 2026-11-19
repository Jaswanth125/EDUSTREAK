import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'task_service.dart';
import 'challenge_service.dart';
import 'store_service.dart';
import 'realtime_chat_service.dart';

class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final ChallengeService _challengeService = ChallengeService();
  final StoreService _storeService = StoreService();
  final RealtimeChatService _chatService = RealtimeChatService();

  Future<void> seedAllData() async {
    try {
      print('Starting seed data process...');

      // Initialize store first (skip if fails - can be done later)
      try {
        await _storeService.initializeStore();
        print('✓ Store initialized');
      } catch (e) {
        print('⚠ Store initialization skipped: $e');
        // Continue with other seed data even if store init fails
      }

      // Create classes
      final class10A = await _createClass('10A', 'Class 10 Section A');
      final class10B = await _createClass('10B', 'Class 10 Section B');
      print('✓ Classes created');

      // Create admin
      final admin = await _createUser(
        email: 'admin@edustreak.com',
        password: 'admin123',
        name: 'Admin User',
        role: 'admin',
      );
      print('✓ Admin created: ${admin.email}');

      // Create teachers
      final teacher1 = await _createUser(
        email: 'teacher1@edustreak.com',
        password: 'teacher123',
        name: 'Ms. Sarah Johnson',
        role: 'teacher',
        classIds: [class10A, class10B],
      );
      final teacher2 = await _createUser(
        email: 'teacher2@edustreak.com',
        password: 'teacher123',
        name: 'Mr. David Smith',
        role: 'teacher',
        classIds: [class10A],
      );
      print('✓ Teachers created');

      // Create students - Class 10A
      final student1 = await _createUser(
        email: 'student1@edustreak.com',
        password: 'student123',
        name: 'Alex Chen',
        role: 'student',
        classId: class10A,
        initialXP: 250,
        initialStreak: 5,
        initialLevel: 3,
      );
      final student2 = await _createUser(
        email: 'student2@edustreak.com',
        password: 'student123',
        name: 'Emma Wilson',
        role: 'student',
        classId: class10A,
        initialXP: 500,
        initialStreak: 10,
        initialLevel: 5,
      );
      final student5 = await _createUser(
        email: 'student5@edustreak.com',
        password: 'student123',
        name: 'James Anderson',
        role: 'student',
        classId: class10A,
        initialXP: 300,
        initialStreak: 7,
        initialLevel: 4,
      );
      final student6 = await _createUser(
        email: 'student6@edustreak.com',
        password: 'student123',
        name: 'Maya Patel',
        role: 'student',
        classId: class10A,
        initialXP: 400,
        initialStreak: 8,
        initialLevel: 4,
      );
      final student7 = await _createUser(
        email: 'student7@edustreak.com',
        password: 'student123',
        name: 'Noah Taylor',
        role: 'student',
        classId: class10A,
        initialXP: 200,
        initialStreak: 4,
        initialLevel: 2,
      );

      // Create students - Class 10B
      final student3 = await _createUser(
        email: 'student3@edustreak.com',
        password: 'student123',
        name: 'Ryan Martinez',
        role: 'student',
        classId: class10B,
        initialXP: 150,
        initialStreak: 3,
        initialLevel: 2,
      );
      final student4 = await _createUser(
        email: 'student4@edustreak.com',
        password: 'student123',
        name: 'Sophia Brown',
        role: 'student',
        classId: class10B,
        initialXP: 800,
        initialStreak: 15,
        initialLevel: 7,
      );
      final student8 = await _createUser(
        email: 'student8@edustreak.com',
        password: 'student123',
        name: 'Olivia White',
        role: 'student',
        classId: class10B,
        initialXP: 350,
        initialStreak: 6,
        initialLevel: 3,
      );
      final student9 = await _createUser(
        email: 'student9@edustreak.com',
        password: 'student123',
        name: 'Lucas Garcia',
        role: 'student',
        classId: class10B,
        initialXP: 450,
        initialStreak: 9,
        initialLevel: 5,
      );
      print('✓ Students created (9 students)');

      // Create parents
      final parent1 = await _createUser(
        email: 'parent1@edustreak.com',
        password: 'parent123',
        name: 'John Chen',
        role: 'parent',
        childId: student1.id,
      );
      await _createUser(
        email: 'parent2@edustreak.com',
        password: 'parent123',
        name: 'Mary Wilson',
        role: 'parent',
        childId: student2.id,
      );
      print('✓ Parents created');

      // Create tasks/assignments - Class 10A
      final task1 = await _createTaskWithId(
        classId: class10A,
        title: 'Math Homework - Algebra',
        description: 'Complete exercises 1-10 from chapter 5. Show all your work.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        dueDate: DateTime.now().subtract(const Duration(days: 2)), // Past due
        maxMarks: 100,
        xpReward: 75,
      );
      
      await _createTaskWithId(
        classId: class10A,
        title: 'Science Project - Solar System',
        description: 'Create a model of the solar system with all planets. Take photos as proof.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        dueDate: DateTime.now().add(const Duration(days: 7)),
        maxMarks: 100,
        xpReward: 100,
      );

      final task3 = await _createTaskWithId(
        classId: class10A,
        title: 'History Assignment - World War II',
        assignedBy: teacher2.id,
        assignedByName: teacher2.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        description: 'Research and write about the causes of World War II. Minimum 3 pages.',
        dueDate: DateTime.now().subtract(const Duration(days: 1)), // Past due
        maxMarks: 100,
        xpReward: 90,
      );

      await _createTaskWithId(
        classId: class10A,
        title: 'Physics Lab Report - Motion',
        description: 'Complete the lab report for the motion experiment. Include graphs and calculations.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        dueDate: DateTime.now().add(const Duration(days: 4)),
        maxMarks: 100,
        xpReward: 85,
      );

      // Create tasks/assignments - Class 10B
      final task5 = await _createTaskWithId(
        classId: class10B,
        title: 'English Essay - My Favorite Book',
        description: 'Write a 500-word essay about your favorite book. Submit as PDF or image.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student3.id, student4.id, student8.id, student9.id],
        dueDate: DateTime.now().subtract(const Duration(days: 3)), // Past due, graded
        maxMarks: 100,
        xpReward: 80,
      );

      await _createTaskWithId(
        classId: class10B,
        title: 'Chemistry Worksheet - Periodic Table',
        description: 'Complete the periodic table worksheet. Answer all questions.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student3.id, student4.id, student8.id, student9.id],
        dueDate: DateTime.now().add(const Duration(days: 6)),
        maxMarks: 100,
        xpReward: 70,
      );

      // Exciting Creative Tasks
      await _createTaskWithId(
        classId: class10A,
        title: '🎨 Creative Writing Challenge - Time Travel Story',
        description: 'Write an exciting 800-word story about traveling back in time to meet a historical figure. Be creative and include vivid descriptions! Submit your story as a document or image.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        dueDate: DateTime.now().add(const Duration(days: 10)),
        maxMarks: 100,
        xpReward: 120,
      );

      await _createTaskWithId(
        classId: class10B,
        title: '🔬 Science Experiment - Build a Volcano',
        description: 'Create a working volcano model using household items. Record a video (2-3 minutes) showing the eruption and explain the chemical reaction. Submit video link or upload video file.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student3.id, student4.id, student8.id, student9.id],
        dueDate: DateTime.now().add(const Duration(days: 12)),
        maxMarks: 100,
        xpReward: 150,
      );

      await _createTaskWithId(
        classId: class10A,
        title: '📊 Data Analysis Project - Climate Change Research',
        description: 'Research climate change data for the last 50 years. Create charts/graphs showing temperature changes. Present your findings in a 5-slide presentation. Upload as PDF or images.',
        assignedBy: teacher2.id,
        assignedByName: teacher2.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        dueDate: DateTime.now().add(const Duration(days: 14)),
        maxMarks: 100,
        xpReward: 130,
      );

      await _createTaskWithId(
        classId: class10B,
        title: '🎭 Drama Performance - Historical Skit',
        description: 'Create a 3-minute skit about a historical event. You can work in groups of 2-3. Record and upload the video. Include costumes and props for bonus points!',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student3.id, student4.id, student8.id, student9.id],
        dueDate: DateTime.now().add(const Duration(days: 9)),
        maxMarks: 100,
        xpReward: 110,
      );

      await _createTaskWithId(
        classId: class10A,
        title: '🌍 Geography Adventure - Virtual World Tour',
        description: 'Choose 5 countries you want to visit. For each country, create a travel brochure with: flag, capital, famous landmarks, and interesting facts. Submit as a PDF or image collage.',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student1.id, student2.id, student5.id, student6.id, student7.id],
        dueDate: DateTime.now().add(const Duration(days: 8)),
        maxMarks: 100,
        xpReward: 100,
      );

      await _createTaskWithId(
        classId: class10B,
        title: '💻 Coding Challenge - Simple Calculator App',
        description: 'Create a simple calculator using any programming language (Python, JavaScript, etc.). Submit your code and a screenshot/demo of it working. Bonus XP for creativity!',
        assignedBy: teacher1.id,
        assignedByName: teacher1.name,
        assignedTo: [student3.id, student4.id, student8.id, student9.id],
        dueDate: DateTime.now().add(const Duration(days: 15)),
        maxMarks: 100,
        xpReward: 140,
      );

      print('✓ Tasks created (12 tasks including exciting creative tasks)');

      // Add submissions and grades to some tasks
      await _addSubmissionAndGrade(task1, student1.id, 85, 'Great work! Keep it up.');
      await _addSubmissionAndGrade(task1, student2.id, 92, 'Excellent! Very detailed.');
      await _addSubmissionAndGrade(task3, student1.id, 78, 'Good effort. Could add more details.');
      await _addSubmissionAndGrade(task3, student2.id, 88, 'Well written!');
      await _addSubmissionAndGrade(task5, student3.id, 90, 'Excellent essay!');
      await _addSubmissionAndGrade(task5, student4.id, 95, 'Outstanding work!');
      await _addSubmissionAndGrade(task5, student8.id, 82, 'Good job!');
      print('✓ Submissions and grades added');

      // Create challenges - assign to all students
      await _createChallenge(
        title: 'Daily Reading Challenge',
        description: 'Read for 30 minutes every day this week',
        xpReward: 50,
        assignedTo: [
          student1.id, student2.id, student3.id, student4.id,
          student5.id, student6.id, student7.id, student8.id, student9.id
        ],
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );
      await _createChallenge(
        title: 'Perfect Week Challenge',
        description: 'Maintain perfect attendance for 5 consecutive days',
        xpReward: 100,
        assignedTo: [
          student1.id, student2.id, student3.id, student4.id,
          student5.id, student6.id, student7.id, student8.id, student9.id
        ],
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );
      print('✓ Challenges created (assigned to all 9 students)');

      // Award some badges
      await _awardBadge(student2.id, 'consistency_king');
      await _awardBadge(student4.id, 'streak_master');
      await _awardBadge(student4.id, 'bronze_warrior');
      print('✓ Badges awarded');

      // Create attendance records for past 7 days
      await _createAttendanceRecords(
        class10A,
        [student1.id, student2.id, student5.id, student6.id, student7.id],
        teacher1.id,
      );
      await _createAttendanceRecords(
        class10B,
        [student3.id, student4.id, student8.id, student9.id],
        teacher1.id,
      );
      print('✓ Attendance records created (past 7 days)');

      // Create chat messages
      await _createChatMessages(teacher1.id, teacher1.name, student1.id, student1.name, student1.role);
      await _createChatMessages(teacher1.id, teacher1.name, student2.id, student2.name, student2.role);
      await _createChatMessages(teacher1.id, teacher1.name, parent1.id, parent1.name, parent1.role);
      await _createChatMessages(teacher2.id, teacher2.name, student1.id, student1.name, student1.role);
      print('✓ Chat messages created');

      print('\n✅ Seed data completed successfully!');
      print('\n📊 Summary:');
      print('  - 9 Students (5 in Class 10A, 4 in Class 10B)');
      print('  - 12 Exciting Homework Assignments (creative tasks included!)');
      print('  - Attendance Records (past 7 days for all students)');
      print('  - 4 Chat Conversations with sample messages');
      print('  - 2 Challenges assigned to all students');
      print('\nLogin credentials:');
      print('Admin: admin@edustreak.com / admin123');
      print('Teacher 1: teacher1@edustreak.com / teacher123 (Classes: 10A, 10B)');
      print('Teacher 2: teacher2@edustreak.com / teacher123 (Class: 10A)');
      print('Student 1: student1@edustreak.com / student123 (Class 10A)');
      print('Student 2: student2@edustreak.com / student123 (Class 10A)');
      print('Student 5-9: student5@edustreak.com / student123 (and so on)');
      print('Parent: parent1@edustreak.com / parent123');
    } catch (e) {
      print('Error seeding data: $e');
      rethrow;
    }
  }

  Future<String> _createClass(String classCode, String className) async {
    final classRef = await _firestore.collection('classes').add({
      'code': classCode,
      'name': className,
      'createdAt': Timestamp.now(),
    });
    return classRef.id;
  }

  Future<UserModel> _createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? classId,
    String? childId,
    List<String>? classIds,
    int initialXP = 0,
    int initialStreak = 0,
    int initialLevel = 1,
  }) async {
    final userModel = await _authService.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      role: role,
      classId: classId,
      childId: childId,
      allowAdminTeacher: true, // Allow admin/teacher creation during seeding
    );

    if (userModel != null) {
      final updates = <String, dynamic>{
        'xp': initialXP,
        'streak': initialStreak,
        'level': initialLevel,
      };

      if (classIds != null) {
        updates['classIds'] = classIds;
      }

      if (role == 'student') {
        updates['schoolId'] = 'sch_ap_001';
        updates['schoolCode'] = 'AP-KRI-042';
        updates['rollNumber'] = email == 'student1@edustreak.com' ? '101' : (email == 'student2@edustreak.com' ? '102' : '103');
        updates['grade'] = '10';
        updates['section'] = 'A';
        updates['academicYear'] = '2024-2025';
      }

      if (role == 'parent' && childId != null) {
        updates['childIds'] = [childId];
      }

      await _firestore.collection('users').doc(userModel.id).update(updates);
      return UserModel.fromMap({
        ...userModel.toMap(),
        ...updates,
      });
    }

    throw Exception('Failed to create user: $email');
  }

  Future<String> _createTaskWithId({
    required String classId,
    required String title,
    required String description,
    required String assignedBy,
    required String assignedByName,
    required List<String> assignedTo,
    required DateTime dueDate,
    int maxMarks = 100,
    int xpReward = 50,
  }) async {
    await _taskService.createTask(
      classId: classId,
      title: title,
      description: description,
      assignedBy: assignedBy,
      assignedByName: assignedByName,
      dueDate: dueDate,
      assignedTo: assignedTo,
      maxMarks: maxMarks,
      xpReward: xpReward,
    );
    
    // Get the task ID that was just created
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('title', isEqualTo: title)
        .where('assignedBy', isEqualTo: assignedBy)
        .limit(1)
        .get();
    
    if (tasksSnapshot.docs.isNotEmpty) {
      return tasksSnapshot.docs.first.id;
    }
    throw Exception('Failed to get task ID for: $title');
  }

  Future<void> _addSubmissionAndGrade(
    String taskId,
    String studentId,
    double marks,
    String feedback,
  ) async {
    try {
      // Mark as submitted
      await _firestore.collection('tasks').doc(taskId).update({
        'submissions.$studentId': 'submitted',
        'proofUrls.$studentId': 'https://example.com/proof.jpg', // Placeholder
      });

      // Add grade
      await _firestore.collection('tasks').doc(taskId).update({
        'marks.$studentId': marks,
        'feedback.$studentId': feedback,
        'submissions.$studentId': 'graded',
      });
    } catch (e) {
      print('Error adding submission/grade: $e');
    }
  }

  Future<void> _createAttendanceRecords(
    String classId,
    List<String> studentIds,
    String teacherId,
  ) async {
    try {
      final now = DateTime.now();
      
      // Create attendance for past 7 days
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        for (var studentId in studentIds) {
          // Randomly mark some as present, some as absent (80% present rate)
          final isPresent = (i % 5 != 0); // 80% present
          final status = isPresent ? 'present' : 'absent';
          
          await _firestore
              .collection('attendance')
              .doc(classId)
              .collection('dates')
              .doc(dateKey)
              .collection('students')
              .doc(studentId)
              .set({
            'id': '${classId}_${studentId}_$dateKey',
            'classId': classId,
            'studentId': studentId,
            'date': Timestamp.fromDate(date),
            'status': status,
            'markedBy': teacherId,
          });
        }
      }
    } catch (e) {
      print('Error creating attendance records: $e');
    }
  }

  Future<void> _createChatMessages(
    String teacherId,
    String teacherName,
    String otherUserId,
    String otherUserName,
    String otherUserRole,
  ) async {
    try {
      // Get or create chat
      final chat = await _chatService.getOrCreateChat(
        currentUserId: teacherId,
        currentUserRole: 'teacher',
        otherUserId: otherUserId,
        otherUserRole: otherUserRole,
      );
      final chatId = chat.id;

      // Create some sample messages
      final messages = [
        'Hello! How can I help you today?',
        'I have a question about the homework assignment.',
        'Sure! What would you like to know?',
        'When is the deadline for the Math homework?',
        'The deadline is in 3 days. Make sure to submit on time!',
        'Thank you for the clarification!',
      ];

      // Add messages with timestamps spread out
      for (int i = 0; i < messages.length; i++) {
        final timestamp = DateTime.now().subtract(Duration(hours: messages.length - i));
        final senderId = i % 2 == 0 ? otherUserId : teacherId;

        final messageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();
        
        await messageRef.set({
          'id': messageRef.id,
          'chatId': chatId,
          'senderId': senderId,
          'text': messages[i],
          'timestamp': Timestamp.fromDate(timestamp),
          'read': senderId == otherUserId ? false : true,
        });

        // Update chat metadata
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': messages[i],
          'lastUpdated': Timestamp.fromDate(timestamp),
        });
      }
    } catch (e) {
      print('Error creating chat messages: $e');
    }
  }

  Future<void> _createChallenge({
    required String title,
    required String description,
    required int xpReward,
    required List<String> assignedTo,
    required DateTime dueDate,
  }) async {
    await _challengeService.createChallenge(
      title: title,
      description: description,
      xpReward: xpReward,
      dueDate: dueDate,
      assignedTo: assignedTo,
    );
  }

  Future<void> _awardBadge(String userId, String badgeId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);
    if (!userBadges.contains(badgeId)) {
      userBadges.add(badgeId);
      await _firestore.collection('users').doc(userId).update({
        'badges': userBadges,
      });
    }
  }
}

