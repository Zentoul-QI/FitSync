import 'package:flutter/foundation.dart';
import 'package:workfit/models/exercise.dart';

class WorkoutProvider with ChangeNotifier {
  String _difficulty = 'beginner';
  List<Exercise> _exercises = [];
  int _currentExerciseIndex = 0;
  DateTime? _workoutStartTime;
  DateTime? _workoutEndTime;
  int _totalRepsCompleted = 0;
  int _totalMistakes = 0; // 🪙 NEW: Track total mistakes for coin calculation

  String get difficulty => _difficulty;
  List<Exercise> get exercises => _exercises;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get totalMistakes => _totalMistakes; // 🪙 NEW: Getter for total mistakes

  Exercise? get currentExercise =>
      _currentExerciseIndex < _exercises.length
          ? _exercises[_currentExerciseIndex]
          : null;

  Duration get workoutDuration {
    if (_workoutStartTime == null) {
      return Duration.zero;
    }

    // If workout is still in progress, calculate time until now
    final endTime = _workoutEndTime ?? DateTime.now();
    return endTime.difference(_workoutStartTime!);
  }

  int get totalRepsCompleted => _totalRepsCompleted;

  void setDifficulty(String difficulty) {
    _difficulty = difficulty;
    _generateExercises();
    notifyListeners();
  }

  void _generateExercises() {
    // Define base reps based on difficulty
    int baseReps;
    switch (_difficulty) {
      case 'beginner':
        baseReps = 10;
        break;
      case 'intermediate':
        baseReps = 15;
        break;
      case 'expert':
        baseReps = 25;
        break;
      default:
        baseReps = 10;
    }

    // Create exercise list (easily modifiable by developer)
    _exercises = [
      Exercise(
        name: 'Squats',
        description: 'Stand with feet shoulder-width apart, lower your body as if sitting back into a chair',
        reps: baseReps,
        exerciseType: 'squat',
      ),
      Exercise(
        name: 'Push-ups',
        description: 'Start in plank position, lower body until chest nearly touches floor',
        reps: baseReps,
        exerciseType: 'pushup',
      ),
      Exercise(
        name: 'Lunges',
        description: 'Step forward with one leg, lowering hips until both knees are bent at 90 degrees',
        reps: baseReps,
        exerciseType: 'lunge',
      ),
      Exercise(
        name: 'Jumping Jacks',
        description: 'Jump while spreading arms and legs, return to starting position',
        reps: baseReps + 5,
        exerciseType: 'jumping_jack',
      ),
      Exercise(
        name: 'Plank Hold',
        description: 'Hold a push-up position with body straight',
        reps: (baseReps * 2), // Duration in seconds
        exerciseType: 'plank',
      ),
    ];
  }

  void startWorkout() {
    _workoutStartTime = DateTime.now();
    _workoutEndTime = null;
    _currentExerciseIndex = 0;
    _totalRepsCompleted = 0;
    _totalMistakes = 0; // 🪙 NEW: Reset mistakes at workout start
    debugPrint('🏋️ Workout started at: $_workoutStartTime');
    notifyListeners();
  }

  // 🪙 NEW: Method to add mistakes from exercise screen
  void addMistakes(int mistakes) {
    _totalMistakes += mistakes;
    debugPrint('🚫 Mistakes added: $mistakes, Total: $_totalMistakes');
    notifyListeners();
  }

  void completeCurrentExercise({int repsCompleted = 0}) {
    _totalRepsCompleted += repsCompleted;
    debugPrint('✅ Exercise completed. Reps: $repsCompleted, Total: $_totalRepsCompleted');

    if (_currentExerciseIndex < _exercises.length - 1) {
      _currentExerciseIndex++;
      debugPrint('➡️ Moving to exercise ${_currentExerciseIndex + 1}/${_exercises.length}');
    } else {
      _workoutEndTime = DateTime.now();
      final duration = workoutDuration;
      debugPrint('🎉 Workout completed! Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
      debugPrint('🚫 Total mistakes: $_totalMistakes'); // 🪙 NEW: Log total mistakes
    }
    notifyListeners();
  }

  bool hasMoreExercises() {
    return _currentExerciseIndex < _exercises.length - 1;
  }

  void reset() {
    _currentExerciseIndex = 0;
    _workoutStartTime = null;
    _workoutEndTime = null;
    _totalRepsCompleted = 0;
    _totalMistakes = 0; // 🪙 NEW: Reset mistakes on provider reset
    notifyListeners();
  }
}