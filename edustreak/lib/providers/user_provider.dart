import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// A reactive [UserProvider] that keeps [currentUser] in sync with
/// Firestore in real time via a snapshot stream.
///
/// Any write to the `users/{uid}` document (XP gain, badge award, streak
/// update, level-up, etc.) will immediately trigger a [notifyListeners] so
/// every widget that reads [currentUser] is rebuilt automatically — no
/// re-login required.
class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  UserModel? get currentUser => _currentUser;

  /// Initialises the streak update (login-time logic) then subscribes to
  /// real-time updates for the user document. Call this once after auth.
  Future<UserModel?> loadUser(String uid) async {
    // Cancel any previous subscription (e.g. if a different user logs in)
    await _userSubscription?.cancel();
    _userSubscription = null;

    try {
      // Fetch user profile immediately
      _currentUser = await _authService.getUserData(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider loadUser error: $e');
    }

    // Safely update daily streak in background
    _authService.updateDailyStreak(uid).catchError((e) {
      debugPrint('Non-fatal streak update error: $e');
    });

    // Start real-time stream — every Firestore update rebuilds the UI
    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        data['id'] = uid; // ensure id is always present
        _currentUser = UserModel.fromMap(data);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('UserProvider stream error: $e');
    });

    return _currentUser;
  }

  /// Writes updated user data to Firestore.
  /// The stream subscription will automatically pick up the change and
  /// call [notifyListeners] — no manual state mutation needed.
  Future<void> updateUser(UserModel user) async {
    await _authService.updateUserData(user);
    // No need to set _currentUser manually — stream handles it
  }

  /// Clears the current user and cancels the Firestore stream.
  void clearUser() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}


