import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
  bool _profileLoaded = false;

  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get userStats => _userStats;
  bool get profileLoaded => _profileLoaded;
  User? get user => _user;
  String? get userId => _user?.uid;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required int age,
    required double weight,
    required double height,
    required String gender,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = cred.user;

      await _firestore.collection('users').doc(_user!.uid).set({
        'email': email,
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'totalWorkouts': 0,
        'totalExercises': 0,
        'totalTimeSpent': 0,
        'dailyStreak': 0,
        'lastLoginDate': FieldValue.serverTimestamp(),
        'totalCoins': 0,
        'lastStreakRewardDate': null,
        'lastStreakMilestone': 0,
      });

      await loadUserProfile();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = cred.user;
      await updateDailyStreak();
      await loadUserProfile();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadUserProfile() async {
    if (_user == null) return;
    try {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(_user!.uid).get();
      _userProfile = doc.data() as Map<String, dynamic>?;
      _userStats = _userProfile;
      _profileLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userProfile != null) return _userProfile;
    await loadUserProfile();
    return _userProfile;
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    if (_userStats != null) return _userStats;
    await loadUserProfile();
    return _userStats;
  }

  Future<void> saveWorkoutSession({
    required String difficulty,
    required int exercisesCompleted,
    required Duration timeSpent,
    required int totalReps,
    required int estimatedCalories,
    int mistakeCount = 0,
    int coinsEarned = 0,
  }) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('workoutHistory')
          .add({
        'difficulty': difficulty,
        'exercisesCompleted': exercisesCompleted,
        'timeSpent': timeSpent.inSeconds,
        'totalReps': totalReps,
        'date': FieldValue.serverTimestamp(),
        'estimatedCalories': estimatedCalories,
        'mistakeCount': mistakeCount,
        'coinsEarned': coinsEarned,
      });

      await _firestore.collection('users').doc(_user!.uid).update({
        'totalWorkouts': FieldValue.increment(1),
        'totalExercises': FieldValue.increment(exercisesCompleted),
        'totalTimeSpent': FieldValue.increment(timeSpent.inSeconds),
        'lastWorkoutDate': FieldValue.serverTimestamp(),
      });

      // Reload profile to get updated coin count
      await loadUserProfile();
    } catch (e) {
      debugPrint('Error saving workout: $e');
    }
  }

  Future<void> updateDailyStreak() async {
    if (_user == null) return;
    try {
      final userDoc = _firestore.collection('users').doc(_user!.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final lastLoginDate = (data['lastLoginDate'] as Timestamp?)?.toDate();
      final currentStreak = data['dailyStreak'] ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastLoginDate == null) {
        await userDoc.update({
          'dailyStreak': 1,
          'lastLoginDate': Timestamp.fromDate(today),
        });
      } else {
        final lastLogin =
        DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
        final diff = today.difference(lastLogin).inDays;

        if (diff == 1) {
          // Consecutive day - increment streak
          final newStreak = currentStreak + 1;
          await userDoc.update({
            'dailyStreak': newStreak,
            'lastLoginDate': Timestamp.fromDate(today),
          });

          // Check if we need to reset the milestone counter after 7 days
          if (newStreak % 7 == 0) {
            await userDoc.update({
              'lastStreakMilestone': 0,
            });
          }
        } else if (diff > 1) {
          // Streak broken - reset everything
          await userDoc.update({
            'dailyStreak': 1,
            'lastLoginDate': Timestamp.fromDate(today),
            'lastStreakMilestone': 0,
          });
        }
      }

      await loadUserProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating daily streak: $e');
    }
  }

  int calculateCalories({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required Duration duration,
    required String difficulty,
  }) {
    double met = 5;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        met = 4.0;
        break;
      case 'medium':
        met = 6.0;
        break;
      case 'hard':
        met = 8.0;
        break;
    }

    double hours = duration.inMinutes / 60.0;
    double calories = met * weight * hours;

    if (gender.toLowerCase() == 'male') calories *= 1.05;
    else calories *= 0.95;

    return calories.round();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userProfile = null;
      _userStats = null;
      _profileLoaded = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Stream<QuerySnapshot> getWorkoutHistory() {
    if (_user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('workoutHistory')
        .orderBy('date', descending: true)
        .snapshots();
  }
}