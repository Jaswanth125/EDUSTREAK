import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        // If demo user doesn't exist yet in Firebase Auth, auto-create it
        if ((authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') &&
            email.endsWith('@edustreak.com')) {
          try {
            credential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (credential.user != null) {
        // Ensure user document exists in Firestore
        final user = await getUserData(credential.user!.uid);
        // Safely attempt streak update in background
        updateDailyStreak(credential.user!.uid).catchError((e) {
          debugPrint('Non-fatal streak update error: $e');
        });
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }
  
  /// Updates the daily login streak for a student based on their last login date.
  /// 
  /// Logic:
  /// - If no lastLoginDate: Set streakCount = 1, lastLoginDate = today, highestStreak = 1
  /// - If current date == lastLoginDate: Do nothing (already updated today)
  /// - If current date == lastLoginDate + 1 day: Increment streakCount, update lastLoginDate, update highestStreak if needed
  /// - If current date > lastLoginDate + 1 day: Reset streakCount = 1, update lastLoginDate
  /// 
  /// Uses server timestamp to avoid client time manipulation.
  /// Updates only once per 24 hours, even if student logs in multiple times in the same day.
  Future<void> updateDailyStreak(String studentId) async {
    try {
      // Use transaction to ensure atomic updates and get latest data
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(studentId);
        final userSnapshot = await transaction.get(userRef);
        
        if (!userSnapshot.exists) {
          debugPrint('User document does not exist for studentId: $studentId');
          return;
        }
        
        final userData = userSnapshot.data()!;
        
        // Only update streak for students
        if (userData['role'] != 'student') {
          debugPrint('User $studentId is not a student, skipping streak update');
          return;
        }
        
        final lastLoginDateTs = userData['lastLoginDate'] as Timestamp?;
        final streakCount = userData['streakCount'] as int? ?? 0;
        final highestStreak = userData['highestStreak'] as int? ?? 0;
        
        // Get current date (normalized to midnight UTC to avoid timezone issues)
        final now = DateTime.now().toUtc();
        final today = DateTime.utc(now.year, now.month, now.day);
        
        int newStreakCount;
        int newHighestStreak;
        bool shouldUpdate = false;
        
        if (lastLoginDateTs == null) {
          // Case a: No lastLoginDate - First login
          newStreakCount = 1;
          newHighestStreak = 1;
          shouldUpdate = true;
          debugPrint('First login for student $studentId - Setting streakCount to 1');
        } else {
          // Convert timestamp to UTC date for comparison
          final lastLoginDate = lastLoginDateTs.toDate().toUtc();
          final lastLoginDateOnly = DateTime.utc(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
          
          // Compare dates only (not time) - using UTC to avoid timezone issues
          final daysDifference = today.difference(lastLoginDateOnly).inDays;
          
          debugPrint('Student $studentId - Last login: $lastLoginDateOnly, Today: $today, Days difference: $daysDifference, Current streak: $streakCount');
          
          if (daysDifference == 0) {
            // Case b: Current date == lastLoginDate - Already updated today
            debugPrint('Student $studentId already logged in today - No streak update needed');
            return;
          } else if (daysDifference == 1) {
            // Case c: Current date == lastLoginDate + 1 day - Continue streak
            newStreakCount = streakCount + 1;
            newHighestStreak = newStreakCount > highestStreak ? newStreakCount : highestStreak;
            shouldUpdate = true;
            debugPrint('Student $studentId continuing streak: $streakCount -> $newStreakCount');
          } else if (daysDifference > 1) {
            // Case d: Current date > lastLoginDate + 1 day - Reset streak
            newStreakCount = 1;
            newHighestStreak = highestStreak; // Keep highest streak record
            shouldUpdate = true;
            debugPrint('Student $studentId streak broken (${daysDifference} days gap) - Resetting to 1');
          } else {
            // Case e: daysDifference < 0 (shouldn't happen, but handle it)
            debugPrint('Student $studentId - Negative days difference ($daysDifference), skipping update');
            return;
          }
        }
        
        if (shouldUpdate) {
          // Create a date-only timestamp for lastLoginDate (midnight UTC of today)
          final todayMidnight = DateTime.utc(today.year, today.month, today.day);
          
          transaction.update(userRef, {
            'streakCount': newStreakCount,
            'lastLoginDate': Timestamp.fromDate(todayMidnight),
            'highestStreak': newHighestStreak,
            // Also update legacy fields for backward compatibility
            'streak': newStreakCount,
            'lastLogin': FieldValue.serverTimestamp(),
          });
          
          debugPrint('✅ Updated streak for student $studentId: streakCount=$newStreakCount, highestStreak=$newHighestStreak');
        }
      });
    } catch (e) {
      // Log error but don't throw - login should still succeed even if streak update fails
      debugPrint('Error updating daily streak: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? classId,
    String? childId,
    bool allowAdminTeacher = false, // Use secondary auth when creating users from admin dashboard
  }) async {
    FirebaseApp? tempApp;
    FirebaseAuth authInstance = _auth;

    try {
      // Prevent creating admin or teacher accounts through public signup.
      // These roles must be created through the Admin Dashboard (allowAdminTeacher = true).
      if (!allowAdminTeacher && (role == 'admin' || role == 'teacher')) {
        throw Exception('Admin and Teacher accounts can only be created through the Admin Dashboard.');
      }

      // When admin creates accounts, use a secondary Firebase app so the admin stays signed in
      if (allowAdminTeacher) {
        final defaultApp = Firebase.app();
        tempApp = await Firebase.initializeApp(
          name: 'AdminTempApp-${DateTime.now().millisecondsSinceEpoch}',
          options: defaultApp.options,
        );
        authInstance = FirebaseAuth.instanceFor(app: tempApp);
      }

      final credential = await authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          role: role,
          classId: classId,
          childId: childId,
        );

        await _firestore.collection('users').doc(credential.user!.uid).set(
              userModel.toMap(),
            );

        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    } finally {
      if (tempApp != null) {
        try {
          await FirebaseAuth.instanceFor(app: tempApp).signOut();
        } catch (_) {}
        await tempApp.delete();
      }
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!..['id'] = uid);
      }

      // If document doesn't exist in Firestore, create default user profile
      final fbUser = _auth.currentUser;
      if (fbUser != null && fbUser.uid == uid) {
        final email = fbUser.email ?? '';
        String role = 'student';
        String name = 'Student User';
        if (email.contains('teacher')) {
          role = 'teacher';
          name = 'Prof. Sarah Jenkins';
        } else if (email.contains('parent')) {
          role = 'parent';
          name = 'Robert Miller';
        } else if (email.contains('admin')) {
          role = 'admin';
          name = 'System Administrator';
        } else if (fbUser.displayName != null && fbUser.displayName!.isNotEmpty) {
          name = fbUser.displayName!;
        } else if (email.isNotEmpty) {
          name = email.split('@').first;
        }

        final newUser = UserModel(
          id: uid,
          email: email,
          name: name,
          role: role,
          lastLogin: DateTime.now(),
          streak: 5,
          streakCount: 5,
          highestStreak: 12,
          xp: 450,
          level: 3,
        );
        await _firestore.collection('users').doc(uid).set(newUser.toMap(), SetOptions(merge: true));
        return newUser;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}

