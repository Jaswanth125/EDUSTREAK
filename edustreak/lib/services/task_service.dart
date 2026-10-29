import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/task_model.dart';
import 'gamification_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GamificationService _gamificationService = GamificationService();

  Future<void> createTask({
    required String classId,
    required String title,
    required String description,
    required String assignedBy,
    required String assignedByName,
    required DateTime dueDate,
    required List<String> assignedTo,
    String subject = '',
    int maxMarks = 100,
    int xpReward = 50,
  }) async {
    try {
      if (kDebugMode) {
        print('Creating task: title=$title, assignedTo=$assignedTo, classId=$classId');
      }
      
      final taskId = _firestore.collection('tasks').doc().id;
      final task = TaskModel(
        id: taskId,
        classId: classId,
        title: title,
        description: description,
        subject: subject,
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        assignedTo: assignedTo,
        maxMarks: maxMarks,
        xpReward: xpReward,
      );

      final taskMap = task.toMap();
      if (kDebugMode) {
        print('Task data to save: assignedTo=${taskMap['assignedTo']}');
      }
      
      await _firestore.collection('tasks').doc(taskId).set(taskMap);
      
      if (kDebugMode) {
        print('Task created successfully with ID: $taskId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task: $e');
      }
      throw Exception('Failed to create task: $e');
    }
  }

  Stream<List<TaskModel>> getTasksForStudent(String studentId) {
    if (studentId.isEmpty) {
      print('Warning: getTasksForStudent called with empty studentId');
      return Stream.value(<TaskModel>[]);
    }
    
    return _firestore
        .collection('tasks')
        .where('assignedTo', arrayContains: studentId)
        .snapshots()
        .map((snapshot) {
      try {
        if (kDebugMode) {
          print('Found ${snapshot.docs.length} tasks for student $studentId');
        }
        
        final tasks = snapshot.docs
            .map((doc) {
              try {
                final taskData = doc.data();
                final assignedTo = List<String>.from(taskData['assignedTo'] ?? []);
                if (kDebugMode) {
                  print('Task ${doc.id}: assignedTo=$assignedTo, studentId=$studentId');
                }
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
        
        // Sort by dueDate in memory (ascending - earliest first)
        tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        
        if (kDebugMode) {
          print('Returning ${tasks.length} tasks for student $studentId');
        }
        
        return tasks;
      } catch (e) {
        if (kDebugMode) {
          print('Error processing tasks for student $studentId: $e');
        }
        return <TaskModel>[];
      }
    }).handleError((error) {
      if (kDebugMode) {
        print('Error in getTasksForStudent stream: $error');
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

      final updates = <String, dynamic>{
        'submissions.$studentId': 'submitted',
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

      // Add XP for submission
      await _gamificationService.addXP(studentId, 25);
      await _gamificationService.checkAssignmentBadges(studentId);

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

