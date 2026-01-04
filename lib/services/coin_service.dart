import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CoinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate coins based on workout completion time
  /// 10-15 minutes = 1 coin
  /// < 10 minutes = 2 coins (bonus for speed)
  /// 15-20 minutes = 0.5 coins (rounded to 1)
  /// > 20 minutes = 0 coins
  int calculateTimeBasedCoins(Duration duration) {
    final minutes = duration.inMinutes;

    if (minutes < 10) {
      return 2; // Bonus for completing quickly
    } else if (minutes >= 10 && minutes <= 15) {
      return 1; // Standard reward
    } else if (minutes > 15 && minutes <= 20) {
      return 1; // Still acceptable time
    } else {
      return 0; // Too slow, no time-based coins
    }
  }

  /// Calculate coins based on mistakes/form accuracy
  /// Perfect form (0 mistakes) = 2 bonus coins
  /// Good form (1-3 mistakes) = 1 bonus coin
  /// Average form (4-6 mistakes) = 0 bonus coins
  /// Poor form (7+ mistakes) = -1 coin penalty
  int calculateAccuracyBasedCoins(int mistakeCount) {
    if (mistakeCount == 0) {
      return 2;
    } else if (mistakeCount <= 3) {
      return 1;
    } else if (mistakeCount <= 6) {
      return 0;
    } else {
      return -1; // Penalty for poor form
    }
  }

  /// Award coins after workout completion
  Future<Map<String, dynamic>> awardWorkoutCoins({
    required String userId,
    required Duration completionTime,
    required int mistakeCount,
    required String workoutId,
  }) async {
    try {
      final timeCoins = calculateTimeBasedCoins(completionTime);
      final accuracyCoins = calculateAccuracyBasedCoins(mistakeCount);
      final totalCoins = timeCoins + accuracyCoins;

      // Ensure minimum 0 coins (no negative total)
      final coinsToAward = totalCoins < 0 ? 0 : totalCoins;

      // Update user's total coins
      await _firestore.collection('users').doc(userId).update({
        'totalCoins': FieldValue.increment(coinsToAward),
      });

      // Save coin transaction to history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('coinHistory')
          .add({
        'amount': coinsToAward,
        'timeCoins': timeCoins,
        'accuracyCoins': accuracyCoins,
        'mistakeCount': mistakeCount,
        'completionTime': completionTime.inSeconds,
        'workoutId': workoutId,
        'reason': 'Workout completion',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('🪙 Awarded $coinsToAward coins to user $userId');

      return {
        'totalCoins': coinsToAward,
        'timeCoins': timeCoins,
        'accuracyCoins': accuracyCoins,
        'breakdown': {
          'time': '${completionTime.inMinutes} min → $timeCoins coins',
          'accuracy': '$mistakeCount mistakes → $accuracyCoins coins',
        }
      };
    } catch (e) {
      debugPrint('❌ Error awarding coins: $e');
      return {
        'totalCoins': 0,
        'timeCoins': 0,
        'accuracyCoins': 0,
        'error': e.toString(),
      };
    }
  }

  /// Check and award streak-based coins
  /// 3-day streak = 2 coins (one-time per cycle)
  /// 7-day streak = 5 coins (resets counter but keeps coins)
  Future<Map<String, dynamic>> checkAndAwardStreakCoins(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return {'coinsAwarded': 0, 'message': 'User not found'};
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final currentStreak = data['dailyStreak'] ?? 0;
      final lastStreakRewardDate = (data['lastStreakRewardDate'] as Timestamp?)?.toDate();
      final lastStreakMilestone = data['lastStreakMilestone'] ?? 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int coinsToAward = 0;
      String message = '';
      int newMilestone = lastStreakMilestone;

      // Check if we've already awarded coins today
      if (lastStreakRewardDate != null) {
        final lastRewardDay = DateTime(
          lastStreakRewardDate.year,
          lastStreakRewardDate.month,
          lastStreakRewardDate.day,
        );

        if (lastRewardDay == today) {
          return {'coinsAwarded': 0, 'message': 'Streak coins already awarded today'};
        }
      }

      // Award coins based on streak milestones
      if (currentStreak >= 7 && lastStreakMilestone < 7) {
        // 7-day streak achieved
        coinsToAward = 5;
        message = '7-day streak! 🔥';
        newMilestone = 7;

        // Reset milestone counter for next cycle (but keep the streak count)
        await _firestore.collection('users').doc(userId).update({
          'lastStreakMilestone': 0, // Reset for next 7-day cycle
          'totalCoins': FieldValue.increment(coinsToAward),
          'lastStreakRewardDate': Timestamp.fromDate(today),
        });
      } else if (currentStreak >= 3 && lastStreakMilestone < 3) {
        // 3-day streak achieved
        coinsToAward = 2;
        message = '3-day streak! 🔥';
        newMilestone = 3;

        await _firestore.collection('users').doc(userId).update({
          'lastStreakMilestone': newMilestone,
          'totalCoins': FieldValue.increment(coinsToAward),
          'lastStreakRewardDate': Timestamp.fromDate(today),
        });
      }

      // Save to coin history if coins were awarded
      if (coinsToAward > 0) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('coinHistory')
            .add({
          'amount': coinsToAward,
          'streakDays': currentStreak,
          'milestone': newMilestone,
          'reason': 'Streak milestone',
          'timestamp': FieldValue.serverTimestamp(),
        });

        debugPrint('🪙 Awarded $coinsToAward coins for $message');
      }

      return {
        'coinsAwarded': coinsToAward,
        'message': message,
        'currentStreak': currentStreak,
        'milestone': newMilestone,
      };
    } catch (e) {
      debugPrint('❌ Error checking streak coins: $e');
      return {
        'coinsAwarded': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get user's total coins
  Future<int> getUserCoins(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['totalCoins'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error getting user coins: $e');
      return 0;
    }
  }

  /// Get coin history stream
  Stream<QuerySnapshot> getCoinHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('coinHistory')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get coin statistics
  Future<Map<String, dynamic>> getCoinStats(String userId) async {
    try {
      final coinHistory = await _firestore
          .collection('users')
          .doc(userId)
          .collection('coinHistory')
          .get();

      int totalWorkoutCoins = 0;
      int totalStreakCoins = 0;
      int totalTransactions = coinHistory.docs.length;

      for (var doc in coinHistory.docs) {
        final data = doc.data();
        final amount = data['amount'] ?? 0;
        final reason = data['reason'] ?? '';

        if (reason.contains('Workout')) {
          totalWorkoutCoins += amount as int;
        } else if (reason.contains('Streak')) {
          totalStreakCoins += amount as int;
        }
      }

      return {
        'totalWorkoutCoins': totalWorkoutCoins,
        'totalStreakCoins': totalStreakCoins,
        'totalTransactions': totalTransactions,
        'totalCoins': totalWorkoutCoins + totalStreakCoins,
      };
    } catch (e) {
      debugPrint('❌ Error getting coin stats: $e');
      return {
        'totalWorkoutCoins': 0,
        'totalStreakCoins': 0,
        'totalTransactions': 0,
        'totalCoins': 0,
      };
    }
  }
}