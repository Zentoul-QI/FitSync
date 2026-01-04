import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workfit/providers/workout_provider.dart';
import 'package:workfit/providers/auth_provider.dart' as app_auth;
import 'package:workfit/services/coin_service.dart';
import 'package:workfit/screens/difficulty_selection_screen.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  int _caloriesBurned = 0;
  bool _isCalculated = false;
  int _coinsEarned = 0;
  int _timeCoins = 0;
  int _accuracyCoins = 0;
  int _streakCoins = 0;
  bool _coinsCalculated = false;
  late AnimationController _coinAnimationController;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();
    _coinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _coinAnimation = CurvedAnimation(
      parent: _coinAnimationController,
      curve: Curves.elasticOut,
    );
    _calculateAndSaveWorkout();
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSaveWorkout() async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      final coinService = CoinService();

      final duration = workoutProvider.workoutDuration;
      final exercisesCompleted = workoutProvider.exercises.length;
      final totalReps = workoutProvider.totalRepsCompleted;
      final difficulty = workoutProvider.difficulty;
      final mistakeCount = workoutProvider.totalMistakes;

      debugPrint('💾 Calculating calories and coins...');

      int calculatedCalories = (duration.inMinutes * 5).toInt();

      try {
        final userProfile = await authProvider.getUserProfile().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⚠️ Profile fetch timeout, using default calculation');
            return null;
          },
        );

        if (userProfile != null && userProfile['age'] != null) {
          final age = userProfile['age'] as int;
          final weight = (userProfile['weight'] as num).toDouble();
          final height = (userProfile['height'] as num).toDouble();
          final gender = userProfile['gender'] as String;

          calculatedCalories = authProvider.calculateCalories(
            age: age,
            weight: weight,
            height: height,
            gender: gender,
            duration: duration,
            difficulty: difficulty,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error getting profile: $e');
      }

      if (mounted) {
        setState(() {
          _caloriesBurned = calculatedCalories;
          _isCalculated = true;
        });
      }

      if (authProvider.userId != null) {
        final coinResult = await coinService.awardWorkoutCoins(
          userId: authProvider.userId!,
          completionTime: duration,
          mistakeCount: mistakeCount,
          workoutId: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        _timeCoins = coinResult['timeCoins'] ?? 0;
        _accuracyCoins = coinResult['accuracyCoins'] ?? 0;
        _coinsEarned = coinResult['totalCoins'] ?? 0;

        final streakResult = await coinService.checkAndAwardStreakCoins(authProvider.userId!);
        _streakCoins = streakResult['coinsAwarded'] ?? 0;

        final totalCoinsWithStreak = _coinsEarned + _streakCoins;

        if (mounted) {
          setState(() {
            _coinsCalculated = true;
          });
          _coinAnimationController.forward();
        }

        if (mounted) {
          setState(() => _isSaving = true);
        }

        await authProvider.saveWorkoutSession(
          difficulty: difficulty,
          exercisesCompleted: exercisesCompleted,
          timeSpent: duration,
          totalReps: totalReps,
          estimatedCalories: calculatedCalories,
          mistakeCount: mistakeCount,
          coinsEarned: totalCoinsWithStreak,
        );

        await authProvider.loadUserProfile();

        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in calculateAndSaveWorkout: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isCalculated = true;
          _coinsCalculated = true;
          final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
          _caloriesBurned = (workoutProvider.workoutDuration.inMinutes * 5).toInt();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final duration = workoutProvider.workoutDuration;
    final exercises = workoutProvider.exercises.length;
    final totalReps = workoutProvider.totalRepsCompleted;
    final mistakeCount = workoutProvider.totalMistakes;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA8D5A7),
              Color(0xFF8FC88E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon with animation
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF7FB77E),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Workout Complete!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isSaving ? 'Saving your progress...' : 'Great job! You crushed it! 💪',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Coins Earned Section
                  if (_coinsCalculated && (_coinsEarned > 0 || _streakCoins > 0))
                    ScaleTransition(
                      scale: _coinAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '+${_coinsEarned + _streakCoins}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Coins Earned!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  if (_timeCoins > 0)
                                    _CoinBreakdownRow(
                                      icon: Icons.timer,
                                      label: 'Time Bonus',
                                      coins: _timeCoins,
                                    ),
                                  if (_accuracyCoins > 0)
                                    _CoinBreakdownRow(
                                      icon: Icons.check_circle,
                                      label: 'Accuracy Bonus',
                                      coins: _accuracyCoins,
                                    ),
                                  if (_accuracyCoins < 0)
                                    _CoinBreakdownRow(
                                      icon: Icons.warning,
                                      label: 'Form Penalty',
                                      coins: _accuracyCoins,
                                    ),
                                  if (_streakCoins > 0)
                                    _CoinBreakdownRow(
                                      icon: Icons.local_fire_department,
                                      label: 'Streak Bonus',
                                      coins: _streakCoins,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        icon: Icons.timer,
                        title: 'Time',
                        value: _formatDuration(duration),
                        color: const Color(0xFF7FB77E),
                      ),
                      _StatCard(
                        icon: Icons.fitness_center,
                        title: 'Exercises',
                        value: '$exercises',
                        color: const Color(0xFF9DC88D),
                      ),
                      _StatCard(
                        icon: Icons.repeat,
                        title: 'Total Reps',
                        value: '$totalReps',
                        color: const Color(0xFFA8D5A7),
                      ),
                      _StatCard(
                        icon: mistakeCount == 0 ? Icons.star : Icons.warning_amber,
                        title: 'Mistakes',
                        value: mistakeCount == 0 ? 'Perfect!' : '$mistakeCount',
                        color: mistakeCount == 0 ? const Color(0xFF7FB77E) : const Color(0xFFE8B87E),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Calories Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8B87E), Color(0xFFD9A066)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Calories Burned',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isCalculated ? '$_caloriesBurned kcal' : 'Calculating...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _FeedbackSection(),
                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const DifficultySelectionScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7FB77E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Color(0xFF7FB77E))
                          : const Text(
                        'Start New Workout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

class _CoinBreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int coins;

  const _CoinBreakdownRow({
    required this.icon,
    required this.label,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            '${coins > 0 ? '+' : ''}$coins',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B8269),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSection extends StatefulWidget {
  @override
  State<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<_FeedbackSection> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'How was your workout?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7FB77E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _selectedRating = index + 1),
                icon: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFD700),
                  size: 32,
                ),
              );
            }),
          ),
          if (_selectedRating > 0)
            Text(
              _getFeedbackText(_selectedRating),
              style: const TextStyle(
                color: Color(0xFF6B8269),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _getFeedbackText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent! Keep it up! 🎉';
      case 4:
        return 'Great work! 💪';
      case 3:
        return 'Good effort! 👍';
      case 2:
        return 'You can do better! 💫';
      case 1:
        return 'Don\'t give up! 🌟';
      default:
        return '';
    }
  }
}