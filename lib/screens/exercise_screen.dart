import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';

import 'package:workfit/providers/workout_provider.dart';
import 'package:workfit/providers/auth_provider.dart';
import 'package:workfit/widgets/pose_painter.dart';
import 'package:workfit/widgets/guide_skeleton_painter.dart';
import 'loading_screen.dart';
import 'summary_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  CameraController? _cameraController;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  bool _isDetecting = false;
  bool _isPaused = false;

  Pose? _currentPose;

  int _repCount = 0;
  int _currentPoseState = 0;
  bool _isInCorrectPosition = false;
  String _userGender = 'male';
  int _mistakeCount = 0;
  int _consecutiveCorrectFrames = 0;
  int _consecutiveIncorrectFrames = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadUserGender();
  }

  Future<void> _loadUserGender() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userStats = await authProvider.getUserStats();
    if (userStats != null && mounted) {
      setState(() {
        _userGender = userStats['gender'] ?? 'male';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      await Future.delayed(const Duration(milliseconds: 500));
      await _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _isPaused) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);

      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty && mounted) {
          setState(() {
            _currentPose = poses.first;
          });
          _checkPoseAndCountRep();
        }
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    }

    _isDetecting = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;

      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      }

      if (rotation == null) {
        return null;
      }

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        return null;
      }

      if (image.planes.isEmpty) {
        return null;
      }

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('InputImage conversion error: $e');
      return null;
    }
  }

  void _checkPoseAndCountRep() {
    if (_currentPose == null) return;

    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final exercise = workoutProvider.currentExercise;
    if (exercise == null) return;

    final matchesGuide = _matchesGuidePose(exercise.name, _currentPoseState);

    if (matchesGuide) {
      _consecutiveCorrectFrames++;
      _consecutiveIncorrectFrames = 0;

      if (!_isInCorrectPosition && _consecutiveCorrectFrames >= 3) {
        setState(() {
          _isInCorrectPosition = true;
          _currentPoseState++;

          final totalStates = _getTotalPoseStates(exercise.name);

          if (_currentPoseState >= totalStates) {
            _currentPoseState = 0;
            _repCount++;

            if (_repCount >= exercise.reps) {
              _completeExercise();
            }
          }
        });
      }
    } else {
      _consecutiveIncorrectFrames++;
      _consecutiveCorrectFrames = 0;

      if (_consecutiveIncorrectFrames == 10) {
        setState(() {
          _mistakeCount++;
          debugPrint('🚫 Mistake count: $_mistakeCount');
        });
      }

      if (_isInCorrectPosition) {
        setState(() {
          _isInCorrectPosition = false;
        });
      }
    }
  }

  int _getTotalPoseStates(String exerciseName) {
    if (exerciseName.toLowerCase().contains('squat')) return 2;
    if (exerciseName.toLowerCase().contains('push')) return 2;
    if (exerciseName.toLowerCase().contains('jack')) return 2;
    if (exerciseName.toLowerCase().contains('lunge')) return 2;
    if (exerciseName.toLowerCase().contains('plank')) return 1;
    return 2;
  }

  bool _matchesGuidePose(String exerciseName, int poseState) {
    if (_currentPose == null) return false;

    final landmarks = _currentPose!.landmarks;

    if (exerciseName.toLowerCase().contains('squat')) {
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final leftKnee = landmarks[PoseLandmarkType.leftKnee];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];

      if (leftHip != null && leftKnee != null && leftAnkle != null) {
        final angle = _calculateAngle(
          leftHip.x, leftHip.y,
          leftKnee.x, leftKnee.y,
          leftAnkle.x, leftAnkle.y,
        );

        if (poseState == 0) {
          return angle > 150;
        } else {
          return angle < 120 && angle > 60;
        }
      }
    }

    if (exerciseName.toLowerCase().contains('push')) {
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final leftElbow = landmarks[PoseLandmarkType.leftElbow];
      final leftWrist = landmarks[PoseLandmarkType.leftWrist];

      if (leftShoulder != null && leftElbow != null && leftWrist != null) {
        final angle = _calculateAngle(
          leftShoulder.x, leftShoulder.y,
          leftElbow.x, leftElbow.y,
          leftWrist.x, leftWrist.y,
        );

        if (poseState == 0) {
          return angle > 160;
        } else {
          return angle < 100;
        }
      }
    }

    if (exerciseName.toLowerCase().contains('jack') ||
        exerciseName.toLowerCase().contains('lunge')) {
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
      final leftWrist = landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = landmarks[PoseLandmarkType.rightWrist];

      if (leftShoulder != null && rightShoulder != null &&
          leftWrist != null && rightWrist != null) {
        final armsRaised = leftWrist.y < leftShoulder.y &&
            rightWrist.y < rightShoulder.y;

        if (poseState == 0) {
          return !armsRaised;
        } else {
          return armsRaised;
        }
      }
    }

    if (exerciseName.toLowerCase().contains('plank')) {
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];

      if (leftShoulder != null && leftHip != null && leftAnkle != null) {
        final bodyAngle = _calculateAngle(
          leftShoulder.x, leftShoulder.y,
          leftHip.x, leftHip.y,
          leftAnkle.x, leftAnkle.y,
        );

        return bodyAngle > 160 && bodyAngle < 200;
      }
    }

    return landmarks.isNotEmpty;
  }

  double _calculateAngle(
      double x1, double y1,
      double x2, double y2,
      double x3, double y3,
      ) {
    final radians = atan2(y3 - y2, x3 - x2) - atan2(y1 - y2, x1 - x2);
    double angle = radians.abs() * 180 / pi;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  Future<void> _completeExercise() async {
    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }

    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    workoutProvider.addMistakes(_mistakeCount);
    workoutProvider.completeCurrentExercise(repsCompleted: _repCount);

    debugPrint('📊 Exercise completed with $_mistakeCount mistakes');

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => workoutProvider.hasMoreExercises()
            ? const LoadingScreen()
            : const SummaryScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final exercise = workoutProvider.currentExercise;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

            Positioned.fill(
              child: CustomPaint(
                painter: GuideSkeletonPainter(
                  exerciseName: exercise?.name ?? '',
                  poseState: _currentPoseState,
                  userPose: _currentPose,
                  isMatching: _isInCorrectPosition,
                  userGender: _userGender,
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: _showExitDialog,
                    ),
                    Column(
                      children: [
                        Text(
                          exercise?.name ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Exercise ${workoutProvider.currentExerciseIndex + 1}/${workoutProvider.exercises.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (_mistakeCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCF7E7E).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Mistakes: $_mistakeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => setState(() => _isPaused = !_isPaused),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: _isInCorrectPosition
                          ? const Color(0xFF7FB77E).withOpacity(0.9)
                          : const Color(0xFFCF7E7E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_repCount / ${exercise?.reps ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isInCorrectPosition ? 'Good Form! ✓' : 'Match the guide',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text('Your current exercise progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Color(0xFFCF7E7E))),
          ),
        ],
      ),
    );
  }
}