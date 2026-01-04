import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final bool isCorrectPosition;

  PosePainter(this.pose, this.isCorrectPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCorrectPosition ? Colors.green : Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = isCorrectPosition ? Colors.greenAccent : Colors.redAccent
      ..strokeWidth = 8.0
      ..style = PaintingStyle.fill;

    // Draw landmarks
    for (final landmark in pose.landmarks.values) {
      canvas.drawCircle(
        Offset(landmark.x, landmark.y),
        6,
        pointPaint,
      );
    }

    // Draw connections
    _drawLine(canvas, paint, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    _drawLine(canvas, paint, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    _drawLine(canvas, paint, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    _drawLine(canvas, paint, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    _drawLine(canvas, paint, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    _drawLine(canvas, paint, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    _drawLine(canvas, paint, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    _drawLine(canvas, paint, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    _drawLine(canvas, paint, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    _drawLine(canvas, paint, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    _drawLine(canvas, paint, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    _drawLine(canvas, paint, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
  }

  void _drawLine(Canvas canvas, Paint paint, PoseLandmarkType from, PoseLandmarkType to) {
    final fromLandmark = pose.landmarks[from];
    final toLandmark = pose.landmarks[to];

    if (fromLandmark != null && toLandmark != null) {
      canvas.drawLine(
        Offset(fromLandmark.x, fromLandmark.y),
        Offset(toLandmark.x, toLandmark.y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.isCorrectPosition != isCorrectPosition;
  }
}