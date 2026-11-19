import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import '../models/task_model.dart';
import 'gamification_service.dart';
import 'in_app_notification_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GamificationService _gamificationService = GamificationService();
  final InAppNotificationService _notificationService = InAppNotificationService();

  Future<String> createTask({
    required String classId,
    required String title,
    required String description,
    required String assignedBy,
    required String assignedByName,
    required DateTime dueDate,
    required List<String> assignedTo,
    String subject = '',
    String schoolId = '',
    String type = 'Homework',
    String chapterOrTopic = '',
    String status = 'published',
    List<Map<String, dynamic>> questions = const [],
    List<String> attachmentUrls = const [],
    List<String> attachmentNames = const [],
    int maxMarks = 100,
    int xpReward = 50,
  }) async {
    try {
      if (kDebugMode) {
        print('Creating task: title=$title, assignedTo=$assignedTo, classId=$classId');
      }
      
      final taskId = _firestore.collection('tasks').doc().id;
      final now = DateTime.now();
      final task = TaskModel(
        id: taskId,
        classId: classId,
        title: title,
        description: description,
        subject: subject,
        schoolId: schoolId,
        type: type,
        chapterOrTopic: chapterOrTopic,
        status: status,
        questions: questions,
        attachmentUrls: attachmentUrls,
        attachmentNames: attachmentNames,
        publishedAt: status == 'published' ? now : null,
        updatedAt: now,
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        dueDate: dueDate,
        createdAt: now,
        assignedTo: assignedTo,
        maxMarks: maxMarks,
        xpReward: xpReward,
      );

      final taskMap = task.toMap();
      await _firestore.collection('tasks').doc(taskId).set(taskMap);
      
      if (kDebugMode) {
        print('Task created successfully with ID: $taskId');
      }

      // Send real-time notifications to all assigned students if published
      if (status == 'published') {
        for (final studentId in assignedTo) {
          try {
            await _notificationService.sendNotification(
              userId: studentId,
              schoolId: schoolId.isNotEmpty ? schoolId : null,
              title: 'New $type: $title',
              body: '$assignedByName assigned "$title" in $subject. Due by ${dueDate.day}/${dueDate.month}/${dueDate.year}.',
              type: 'assignment_published',
              metadata: {
                'taskId': taskId,
                'subject': subject,
                'dueDate': dueDate.toIso8601String(),
              },
            );
          } catch (_) {}
        }
      }

      return taskId;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task: $e');
      }
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? subject,
    String? classId,
    DateTime? dueDate,
    int? maxMarks,
    int? xpReward,
    String? type,
    String? chapterOrTopic,
    String? status,
    List<Map<String, dynamic>>? questions,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
    List<String>? assignedTo,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (subject != null) updates['subject'] = subject;
      if (classId != null) updates['classId'] = classId;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
      if (maxMarks != null) updates['maxMarks'] = maxMarks;
      if (xpReward != null) updates['xpReward'] = xpReward;
      if (type != null) updates['type'] = type;
      if (chapterOrTopic != null) updates['chapterOrTopic'] = chapterOrTopic;
      if (status != null) {
        updates['status'] = status;
        if (status == 'published') updates['publishedAt'] = Timestamp.now();
      }
      if (questions != null) updates['questions'] = questions;
      if (attachmentUrls != null) updates['attachmentUrls'] = attachmentUrls;
      if (attachmentNames != null) updates['attachmentNames'] = attachmentNames;
      if (assignedTo != null) updates['assignedTo'] = assignedTo;

      await _firestore.collection('tasks').doc(taskId).update(updates);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> archiveTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'archived',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to archive task: $e');
    }
  }

  List<TaskModel> _mapDocSnapshots(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      final tasks = snapshot.docs
          .map((doc) {
            try {
              final taskData = doc.data();
              return TaskModel.fromMap(taskData..['id'] = doc.id);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing task ${doc.id}: $e');
              }
              return null;
            }
          })
          .where((task) => task != null)
          .cast<TaskModel>()
          .toList();

      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing task snapshot: $e');
      }
      return <TaskModel>[];
    }
  }

  Stream<List<TaskModel>> getTasksForStudent(String studentId, {String? classId}) {
    if (studentId.isEmpty) {
      return Stream.value(<TaskModel>[]);
    }

    final studentStream = _firestore
        .collection('tasks')
        .where('assignedTo', arrayContains: studentId)
        .snapshots()
        .map(_mapDocSnapshots);

    if (classId == null || classId.isEmpty) {
      return studentStream;
    }

    final classStream = _firestore
        .collection('tasks')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(_mapDocSnapshots);

    return Rx.combineLatest2(studentStream, classStream, (List<TaskModel> l1, List<TaskModel> l2) {
      final map = <String, TaskModel>{};
      for (final t in l1) {
        map[t.id] = t;
      }
      for (final t in l2) {
        map[t.id] = t;
      }
      final combined = map.values.toList();
      combined.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return combined;
    }).handleError((error) {
      if (kDebugMode) {
        print('Error in getTasksForStudent combined stream: $error');
      }
      return <TaskModel>[];
    });
  }

  Stream<List<TaskModel>> getTasksForTeacher(String teacherId) {
    if (kDebugMode) {
      print('Getting tasks for teacher: $teacherId');
    }
    
    return _firestore
        .collection('tasks')
        .where('assignedBy', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
      if (kDebugMode) {
        print('Found ${snapshot.docs.length} tasks for teacher $teacherId');
      }
      
      final tasks = snapshot.docs
          .map((doc) {
            try {
              return TaskModel.fromMap(doc.data()..['id'] = doc.id);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing task ${doc.id}: $e');
              }
              return null;
            }
          })
          .where((task) => task != null)
          .cast<TaskModel>()
          .toList();
      
      // Sort by dueDate in memory (descending - newest first)
      tasks.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      
      if (kDebugMode) {
        print('Returning ${tasks.length} tasks for teacher $teacherId');
      }
      
      return tasks;
    }).handleError((error) {
      if (kDebugMode) {
        print('Error in getTasksForTeacher stream: $error');
      }
      // Return empty list on error instead of crashing
      return <TaskModel>[];
    });
  }

  Stream<List<TaskModel>> getTasksForClass(String classId) {
    return _firestore
        .collection('tasks')
        .where('classId', isEqualTo: classId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    });
  }

  Future<String> uploadProofFile(String taskId, String studentId, File file) async {
    try {
      final fileName = '${taskId}_${studentId}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child('task_proofs/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload proof file: $e');
    }
  }

  Future<String> uploadProofFileFromBytes(
    String taskId,
    String studentId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final storageFileName = '${taskId}_${studentId}_$timestamp.$extension';
      final ref = _storage.ref().child('task_proofs/$storageFileName');
      await ref.putData(fileBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload proof file: $e');
    }
  }

  Future<void> submitTask({
    required String taskId,
    required String studentId,
    String? proofFileUrl,
    String? submissionText,
    String? message,
  }) async {
    try {
      if (kDebugMode) {
        print('Submitting task: taskId=$taskId, studentId=$studentId');
        print('Submission text length: ${submissionText?.length ?? 0}');
      }

      final taskRef = _firestore.collection('tasks').doc(taskId);
      final taskDoc = await taskRef.get();

      if (!taskDoc.exists) {
        if (kDebugMode) {
          print('ERROR: Task $taskId not found in Firestore');
        }
        throw Exception('Task not found');
      }

      final existingSub = (taskDoc.data()?['submissions'] as Map<String, dynamic>?)?[studentId];
      final isFirstSubmission = existingSub != 'submitted' && existingSub != 'graded';

      final updates = <String, dynamic>{
        'submissions.$studentId': 'submitted',
        'submissionDates.$studentId': Timestamp.now(),
      };

      // Save text submission (preferred method)
      if (submissionText != null && submissionText.isNotEmpty) {
        updates['submissionTexts.$studentId'] = submissionText;
        if (kDebugMode) {
          print('Saving submission text for student $studentId');
        }
      } else {
        if (kDebugMode) {
          print('WARNING: No submission text provided');
        }
      }

      // Keep proofFileUrl for backward compatibility
      if (proofFileUrl != null) {
        updates['proofUrls.$studentId'] = proofFileUrl;
      }

      if (kDebugMode) {
        print('Updating task with: $updates');
      }

      await taskRef.update(updates);

      if (kDebugMode) {
        print('Task updated successfully');
      }

      // Add XP for first submission only (idempotent)
      if (isFirstSubmission) {
        await _gamificationService.addXP(studentId, 25);
        await _gamificationService.checkAssignmentBadges(studentId);
      }

      // Notify teacher in real time
      try {
        final teacherId = taskDoc.data()?['assignedBy']?.toString() ?? '';
        final taskTitle = taskDoc.data()?['title']?.toString() ?? 'Assignment';
        if (teacherId.isNotEmpty) {
          final studentDoc = await _firestore.collection('users').doc(studentId).get();
          final studentName = studentDoc.data()?['name']?.toString() ?? 'A student';
          await _notificationService.sendNotification(
            userId: teacherId,
            title: 'Homework Submitted',
            body: '$studentName submitted work for "$taskTitle".',
            type: 'assignment_submitted',
            metadata: {'taskId': taskId, 'studentId': studentId},
          );
        }
      } catch (_) {}

      if (kDebugMode) {
        print('Submission complete! XP added to student');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR submitting task: $e');
      }
      throw Exception('Failed to submit task: $e');
    }
  }

  Future<void> gradeTask({
    required String taskId,
    required String studentId,
    required double marks,
    String? feedback,
    String? letterGrade, // A, B, C, etc.
  }) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);
      final taskDoc = await taskRef.get();

      if (!taskDoc.exists) throw Exception('Task not found');

      final task = TaskModel.fromMap(taskDoc.data()!..['id'] = taskDoc.id);

      // Calculate points based on letter grade or marks
      int pointsAwarded = 0;
      if (letterGrade != null) {
        // Letter grade to points mapping
        final gradeToPoints = {'A': 10, 'B': 8, 'C': 5, 'D': 3, 'F': 0};
        pointsAwarded = gradeToPoints[letterGrade.toUpperCase()] ?? 0;
      } else {
        // Calculate points based on percentage of max marks
        final percentage = marks / task.maxMarks;
        if (percentage >= 0.9) {
          pointsAwarded = 10; // A equivalent
        } else if (percentage >= 0.8) {
          pointsAwarded = 8; // B equivalent
        } else if (percentage >= 0.7) {
          pointsAwarded = 5; // C equivalent
        } else if (percentage >= 0.6) {
          pointsAwarded = 3; // D equivalent
        } else {
          pointsAwarded = 0; // F equivalent
        }
      }

      final updates = <String, dynamic>{
        'submissions.$studentId': 'graded',
        'marks.$studentId': marks,
        'pointsAwarded.$studentId': pointsAwarded,
      };

      if (feedback != null) {
        updates['feedback.$studentId'] = feedback;
      }

      // Calculate total XP to award (pointsAwarded + bonus based on marks)
      final xpBonus = (marks / task.maxMarks * task.xpReward).round();
      final totalXPToAward = pointsAwarded + xpBonus;

      // Update task with grading information first
      await taskRef.update(updates);

      if (kDebugMode) {
        print('Task updated with grading information');
      }

      // Update student's XP immediately
      final userRef = _firestore.collection('users').doc(studentId);
      
      // Get current XP to calculate new level
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('Student not found');
      }

      final userData = userDoc.data()!;
      final currentXP = (userData['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (userData['level'] as num?)?.toInt() ?? 1;
      final newXP = currentXP + totalXPToAward;

      // Helper function to calculate level from XP
      int getLevelFromXP(int xp) {
        int getXPForLevel(int level) {
          return (level * 100) * (level + 1);
        }
        int level = 1;
        while (getXPForLevel(level) <= xp) {
          level++;
        }
        return level - 1;
      }

      final newLevel = getLevelFromXP(newXP);

      // Update XP and level directly
      await userRef.update({
        'xp': newXP,
        'level': newLevel,
      });

      if (kDebugMode) {
        print('✅ Awarded $totalXPToAward XP to student $studentId (points: $pointsAwarded + bonus: $xpBonus)');
        print('   XP: $currentXP -> $newXP, Level: $currentLevel -> $newLevel');
      }

      // Check for badges after XP update (outside transaction for performance)
      if (marks >= 90) {
        await _gamificationService.checkAssignmentBadges(studentId);
      }
      if (marks == task.maxMarks) {
        await _gamificationService.awardBadge(studentId, 'perfectionist');
      }
      
      // Check for level up badges (using the newLevel we already calculated)
      await _gamificationService.checkLevelBadges(studentId, newLevel);

      // Send real-time notification to the student
      try {
        await _notificationService.sendNotification(
          userId: studentId,
          schoolId: task.schoolId.isNotEmpty ? task.schoolId : null,
          title: 'Assignment Graded: ${task.title}',
          body: 'Your teacher graded your work: ${marks.toStringAsFixed(0)}/${task.maxMarks}.${feedback != null && feedback.isNotEmpty ? ' Feedback: "$feedback"' : ''}',
          type: 'assignment_graded',
          metadata: {
            'taskId': taskId,
            'marks': marks,
            'maxMarks': task.maxMarks,
            'feedback': feedback,
          },
        );
      } catch (_) {}
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('ERROR in gradeTask: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Failed to grade task: ${e.toString()}');
    }
  }

  Future<void> completeTask(String taskId, String studentId) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);
      await taskRef.update({
        'submissions.$studentId': 'completed',
      });

      // Get task for XP reward
      final taskDoc = await taskRef.get();
      if (taskDoc.exists) {
        final task = TaskModel.fromMap(taskDoc.data()!..['id'] = taskDoc.id);
        await _gamificationService.addXP(studentId, task.xpReward);
        await _gamificationService.checkAssignmentBadges(studentId);
      }
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }
}

