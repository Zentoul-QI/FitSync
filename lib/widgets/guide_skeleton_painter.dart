import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class GuideSkeletonPainter extends CustomPainter {
  final String exerciseName;
  final int poseState;
  final Pose? userPose;
  final bool isMatching;
  final String userGender;

  GuideSkeletonPainter({
    required this.exerciseName,
    required this.poseState,
    this.userPose,
    this.isMatching = false,
    this.userGender = 'male',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.height / 10;

    Color fillColor;
    Color borderColor;

    if (userPose != null && _isUserInsideGuide(userPose!, size)) {
      if (isMatching) {
        fillColor = Colors.lightGreen.withOpacity(0.25);
        borderColor = Colors.green.withOpacity(0.65);
      } else {
        fillColor = Colors.red.withOpacity(0.25);
        borderColor = Colors.red.withOpacity(0.65);
      }
    } else {
      fillColor = Colors.grey.withOpacity(0.15);
      borderColor = Colors.grey.withOpacity(0.45);
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (exerciseName.toLowerCase().contains('squat')) {
      _drawSquatPose(canvas, centerX, centerY, scale, fillPaint, borderPaint, poseState);
    } else if (exerciseName.toLowerCase().contains('push')) {
      _drawPushUpPose(canvas, centerX, centerY, scale, fillPaint, borderPaint, poseState);
    } else if (exerciseName.toLowerCase().contains('jack')) {
      _drawJumpingJackPose(canvas, centerX, centerY, scale, fillPaint, borderPaint, poseState);
    } else if (exerciseName.toLowerCase().contains('lunge')) {
      _drawLungePose(canvas, centerX, centerY, scale, fillPaint, borderPaint, poseState);
    } else if (exerciseName.toLowerCase().contains('plank')) {
      _drawPlankPose(canvas, centerX, centerY, scale, fillPaint, borderPaint);
    } else {
      _drawStandingPose(canvas, centerX, centerY, scale, fillPaint, borderPaint);
    }
  }

  bool _isUserInsideGuide(Pose pose, Size size) {
    final landmarks = pose.landmarks;
    if (landmarks.isEmpty) return false;

    final nose = landmarks[PoseLandmarkType.nose];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return false;
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final guideRadius = size.height / 3.5;

    final noseDist = (nose.x - centerX).abs() + (nose.y - centerY).abs();
    final shoulderDist = ((leftShoulder.x + rightShoulder.x) / 2 - centerX).abs() +
        ((leftShoulder.y + rightShoulder.y) / 2 - centerY).abs();

    return noseDist < guideRadius && shoulderDist < guideRadius;
  }

  void _drawBodyPart(Canvas canvas, Offset start, Offset end, double width, Paint fillPaint, Paint borderPaint) {
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final perpAngle = angle + pi / 2;

    final path = Path();
    path.moveTo(start.dx + cos(perpAngle) * width / 2, start.dy + sin(perpAngle) * width / 2);
    path.lineTo(end.dx + cos(perpAngle) * width / 2, end.dy + sin(perpAngle) * width / 2);
    path.lineTo(end.dx - cos(perpAngle) * width / 2, end.dy - sin(perpAngle) * width / 2);
    path.lineTo(start.dx - cos(perpAngle) * width / 2, start.dy - sin(perpAngle) * width / 2);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawJoint(Canvas canvas, Offset position, double radius, Paint fillPaint, Paint borderPaint) {
    canvas.drawCircle(position, radius, fillPaint);
    canvas.drawCircle(position, radius, borderPaint);
  }

  void _drawArticulatedBody(Canvas canvas, {
    required Offset headCenter,
    required double headRadius,
    required Offset neckJoint,
    required Offset leftShoulderJoint,
    required Offset rightShoulderJoint,
    required Offset waistCenter,
    required Offset leftElbowJoint,
    required Offset rightElbowJoint,
    required Offset leftHandJoint,
    required Offset rightHandJoint,
    required Offset leftHipJoint,
    required Offset rightHipJoint,
    required Offset leftKneeJoint,
    required Offset rightKneeJoint,
    required Offset leftFootJoint,
    required Offset rightFootJoint,
    required Paint fillPaint,
    required Paint borderPaint,
    required double scale,
  }) {
    final jointRadius = 0.08 * scale;
    final torsoWidth = 0.35 * scale;
    final limbWidth = 0.12 * scale;

    _drawBodyPart(canvas, neckJoint, waistCenter, torsoWidth, fillPaint, borderPaint);

    _drawBodyPart(canvas, leftShoulderJoint, leftElbowJoint, limbWidth, fillPaint, borderPaint);
    _drawBodyPart(canvas, leftElbowJoint, leftHandJoint, limbWidth * 0.9, fillPaint, borderPaint);

    _drawBodyPart(canvas, rightShoulderJoint, rightElbowJoint, limbWidth, fillPaint, borderPaint);
    _drawBodyPart(canvas, rightElbowJoint, rightHandJoint, limbWidth * 0.9, fillPaint, borderPaint);

    _drawBodyPart(canvas, leftHipJoint, leftKneeJoint, limbWidth * 1.1, fillPaint, borderPaint);
    _drawBodyPart(canvas, leftKneeJoint, leftFootJoint, limbWidth, fillPaint, borderPaint);

    _drawBodyPart(canvas, rightHipJoint, rightKneeJoint, limbWidth * 1.1, fillPaint, borderPaint);
    _drawBodyPart(canvas, rightKneeJoint, rightFootJoint, limbWidth, fillPaint, borderPaint);

    canvas.drawCircle(headCenter, headRadius, fillPaint);
    canvas.drawCircle(headCenter, headRadius, borderPaint);

    _drawJoint(canvas, neckJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, leftShoulderJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, rightShoulderJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, waistCenter, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, leftElbowJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, rightElbowJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, leftHandJoint, jointRadius * 0.8, fillPaint, borderPaint);
    _drawJoint(canvas, rightHandJoint, jointRadius * 0.8, fillPaint, borderPaint);
    _drawJoint(canvas, leftHipJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, rightHipJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, leftKneeJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, rightKneeJoint, jointRadius, fillPaint, borderPaint);
    _drawJoint(canvas, leftFootJoint, jointRadius * 0.8, fillPaint, borderPaint);
    _drawJoint(canvas, rightFootJoint, jointRadius * 0.8, fillPaint, borderPaint);
  }

  void _drawSquatPose(Canvas canvas, double centerX, double centerY, double scale, Paint fillPaint, Paint borderPaint, int state) {
    final headRadius = 0.32 * scale;

    if (state == 0) {
      final headCenter = Offset(centerX, centerY - 2.5 * scale);
      final neckJoint = Offset(centerX, centerY - 2.0 * scale);
      final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 1.95 * scale);
      final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 1.95 * scale);
      final waistCenter = Offset(centerX, centerY - 0.2 * scale);
      final leftElbowJoint = Offset(centerX - 0.65 * scale, centerY - 0.9 * scale);
      final rightElbowJoint = Offset(centerX + 0.65 * scale, centerY - 0.9 * scale);
      final leftHandJoint = Offset(centerX - 0.75 * scale, centerY + 0.1 * scale);
      final rightHandJoint = Offset(centerX + 0.75 * scale, centerY + 0.1 * scale);
      final leftHipJoint = Offset(centerX - 0.35 * scale, centerY - 0.15 * scale);
      final rightHipJoint = Offset(centerX + 0.35 * scale, centerY - 0.15 * scale);
      final leftKneeJoint = Offset(centerX - 0.4 * scale, centerY + 1.0 * scale);
      final rightKneeJoint = Offset(centerX + 0.4 * scale, centerY + 1.0 * scale);
      final leftFootJoint = Offset(centerX - 0.4 * scale, centerY + 2.2 * scale);
      final rightFootJoint = Offset(centerX + 0.4 * scale, centerY + 2.2 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    } else {
      final headCenter = Offset(centerX, centerY - 1.3 * scale);
      final neckJoint = Offset(centerX, centerY - 0.8 * scale);
      final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 0.75 * scale);
      final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 0.75 * scale);
      final waistCenter = Offset(centerX, centerY + 0.6 * scale);
      final leftElbowJoint = Offset(centerX - 0.75 * scale, centerY + 0.3 * scale);
      final rightElbowJoint = Offset(centerX + 0.75 * scale, centerY + 0.3 * scale);
      final leftHandJoint = Offset(centerX - 0.85 * scale, centerY + 1.1 * scale);
      final rightHandJoint = Offset(centerX + 0.85 * scale, centerY + 1.1 * scale);
      final leftHipJoint = Offset(centerX - 0.4 * scale, centerY + 0.65 * scale);
      final rightHipJoint = Offset(centerX + 0.4 * scale, centerY + 0.65 * scale);
      final leftKneeJoint = Offset(centerX - 0.55 * scale, centerY + 1.4 * scale);
      final rightKneeJoint = Offset(centerX + 0.55 * scale, centerY + 1.4 * scale);
      final leftFootJoint = Offset(centerX - 0.5 * scale, centerY + 2.2 * scale);
      final rightFootJoint = Offset(centerX + 0.5 * scale, centerY + 2.2 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    }
  }

  void _drawPushUpPose(Canvas canvas, double centerX, double centerY, double scale, Paint fillPaint, Paint borderPaint, int state) {
    final headRadius = 0.22 * scale;

    if (state == 0) {
      // UP POSITION (Image 1 - Arms straight, body elevated)
      // Body is horizontal, parallel to the ground line

      // Head on the right side
      final headCenter = Offset(centerX + 2.0 * scale, centerY - 0.8 * scale);
      final neckJoint = Offset(centerX + 1.7 * scale, centerY - 0.8 * scale);

      // Shoulders
      final leftShoulderJoint = Offset(centerX + 1.6 * scale, centerY - 0.7 * scale);
      final rightShoulderJoint = Offset(centerX + 1.6 * scale, centerY - 0.9 * scale);

      // Waist/hips area
      final waistCenter = Offset(centerX - 0.3 * scale, centerY - 0.8 * scale);

      // Arms - STRAIGHT DOWN (supporting body)
      final leftElbowJoint = Offset(centerX + 1.1 * scale, centerY - 0.3 * scale);
      final rightElbowJoint = Offset(centerX + 1.1 * scale, centerY - 0.5 * scale);
      final leftHandJoint = Offset(centerX + 1.0 * scale, centerY + 0.0 * scale);  // On ground line
      final rightHandJoint = Offset(centerX + 1.0 * scale, centerY + 0.0 * scale); // On ground line

      // Hips
      final leftHipJoint = Offset(centerX - 0.25 * scale, centerY - 0.7 * scale);
      final rightHipJoint = Offset(centerX - 0.25 * scale, centerY - 0.9 * scale);

      // Legs - horizontal
      final leftKneeJoint = Offset(centerX - 1.0 * scale, centerY - 0.7 * scale);
      final rightKneeJoint = Offset(centerX - 1.0 * scale, centerY - 0.9 * scale);

      // Feet on ground
      final leftFootJoint = Offset(centerX - 1.8 * scale, centerY + 0.0 * scale);
      final rightFootJoint = Offset(centerX - 1.8 * scale, centerY + 0.0 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    } else {
      // DOWN POSITION (Image 2 - Arms bent, body lowered closer to ground)

      // Head on the right side (slightly lower)
      final headCenter = Offset(centerX + 2.0 * scale, centerY - 0.3 * scale);
      final neckJoint = Offset(centerX + 1.7 * scale, centerY - 0.3 * scale);

      // Shoulders (lower position)
      final leftShoulderJoint = Offset(centerX + 1.6 * scale, centerY - 0.2 * scale);
      final rightShoulderJoint = Offset(centerX + 1.6 * scale, centerY - 0.4 * scale);

      // Waist (lower but still straight line)
      final waistCenter = Offset(centerX - 0.3 * scale, centerY - 0.3 * scale);

      // Arms - BENT (elbows at 90 degrees)
      final leftElbowJoint = Offset(centerX + 1.3 * scale, centerY - 0.5 * scale);
      final rightElbowJoint = Offset(centerX + 1.3 * scale, centerY - 0.7 * scale);
      final leftHandJoint = Offset(centerX + 1.0 * scale, centerY + 0.0 * scale);  // On ground
      final rightHandJoint = Offset(centerX + 1.0 * scale, centerY + 0.0 * scale); // On ground

      // Hips (lower)
      final leftHipJoint = Offset(centerX - 0.25 * scale, centerY - 0.2 * scale);
      final rightHipJoint = Offset(centerX - 0.25 * scale, centerY - 0.4 * scale);

      // Legs - still horizontal
      final leftKneeJoint = Offset(centerX - 1.0 * scale, centerY - 0.2 * scale);
      final rightKneeJoint = Offset(centerX - 1.0 * scale, centerY - 0.4 * scale);

      // Feet on ground
      final leftFootJoint = Offset(centerX - 1.8 * scale, centerY + 0.0 * scale);
      final rightFootJoint = Offset(centerX - 1.8 * scale, centerY + 0.0 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    }
  }


  void _drawJumpingJackPose(Canvas canvas, double centerX, double centerY, double scale, Paint fillPaint, Paint borderPaint, int state) {
    final headRadius = 0.32 * scale;

    if (state == 0) {
      final headCenter = Offset(centerX, centerY - 2.5 * scale);
      final neckJoint = Offset(centerX, centerY - 2.0 * scale);
      final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 1.95 * scale);
      final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 1.95 * scale);
      final waistCenter = Offset(centerX, centerY - 0.2 * scale);
      final leftElbowJoint = Offset(centerX - 0.65 * scale, centerY - 0.9 * scale);
      final rightElbowJoint = Offset(centerX + 0.65 * scale, centerY - 0.9 * scale);
      final leftHandJoint = Offset(centerX - 0.75 * scale, centerY + 0.1 * scale);
      final rightHandJoint = Offset(centerX + 0.75 * scale, centerY + 0.1 * scale);
      final leftHipJoint = Offset(centerX - 0.35 * scale, centerY - 0.15 * scale);
      final rightHipJoint = Offset(centerX + 0.35 * scale, centerY - 0.15 * scale);
      final leftKneeJoint = Offset(centerX - 0.4 * scale, centerY + 1.0 * scale);
      final rightKneeJoint = Offset(centerX + 0.4 * scale, centerY + 1.0 * scale);
      final leftFootJoint = Offset(centerX - 0.4 * scale, centerY + 2.2 * scale);
      final rightFootJoint = Offset(centerX + 0.4 * scale, centerY + 2.2 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );

    } else {
      final headCenter = Offset(centerX, centerY - 2.5 * scale);
      final neckJoint = Offset(centerX, centerY - 2.0 * scale);
      final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 1.95 * scale);
      final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 1.95 * scale);
      final waistCenter = Offset(centerX, centerY - 0.2 * scale);
      final leftElbowJoint = Offset(centerX - 1.1 * scale, centerY - 2.4 * scale);
      final rightElbowJoint = Offset(centerX + 1.1 * scale, centerY - 2.4 * scale);
      final leftHandJoint = Offset(centerX - 1.4 * scale, centerY - 2.9 * scale);
      final rightHandJoint = Offset(centerX + 1.4 * scale, centerY - 2.9 * scale);
      final leftHipJoint = Offset(centerX - 0.35 * scale, centerY - 0.15 * scale);
      final rightHipJoint = Offset(centerX + 0.35 * scale, centerY - 0.15 * scale);
      final leftKneeJoint = Offset(centerX - 0.8 * scale, centerY + 1.0 * scale);
      final rightKneeJoint = Offset(centerX + 0.8 * scale, centerY + 1.0 * scale);
      final leftFootJoint = Offset(centerX - 1.1 * scale, centerY + 2.2 * scale);
      final rightFootJoint = Offset(centerX + 1.1 * scale, centerY + 2.2 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    }
  }

  void _drawLungePose(Canvas canvas, double centerX, double centerY, double scale, Paint fillPaint, Paint borderPaint, int state) {
    final headRadius = 0.32 * scale;

    if (state == 0) {
      final headCenter = Offset(centerX, centerY - 2.5 * scale);
      final neckJoint = Offset(centerX, centerY - 2.0 * scale);
      final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 1.95 * scale);
      final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 1.95 * scale);
      final waistCenter = Offset(centerX, centerY - 0.2 * scale);
      final leftElbowJoint = Offset(centerX - 0.65 * scale, centerY - 0.9 * scale);
      final rightElbowJoint = Offset(centerX + 0.65 * scale, centerY - 0.9 * scale);
      final leftHandJoint = Offset(centerX - 0.75 * scale, centerY + 0.1 * scale);
      final rightHandJoint = Offset(centerX + 0.75 * scale, centerY + 0.1 * scale);
      final leftHipJoint = Offset(centerX - 0.35 * scale, centerY - 0.15 * scale);
      final rightHipJoint = Offset(centerX + 0.35 * scale, centerY - 0.15 * scale);
      final leftKneeJoint = Offset(centerX - 0.4 * scale, centerY + 1.0 * scale);
      final rightKneeJoint = Offset(centerX + 0.4 * scale, centerY + 1.0 * scale);
      final leftFootJoint = Offset(centerX - 0.4 * scale, centerY + 2.2 * scale);
      final rightFootJoint = Offset(centerX + 0.4 * scale, centerY + 2.2 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    } else {
      final headCenter = Offset(centerX, centerY - 2.0 * scale);
      final neckJoint = Offset(centerX, centerY - 1.5 * scale);
      final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 1.45 * scale);
      final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 1.45 * scale);
      final waistCenter = Offset(centerX + 0.2 * scale, centerY - 0.1 * scale);
      final leftElbowJoint = Offset(centerX - 0.75 * scale, centerY - 0.5 * scale);
      final rightElbowJoint = Offset(centerX + 0.75 * scale, centerY - 0.5 * scale);
      final leftHandJoint = Offset(centerX - 0.85 * scale, centerY + 0.5 * scale);
      final rightHandJoint = Offset(centerX + 0.85 * scale, centerY + 0.5 * scale);
      final leftHipJoint = Offset(centerX - 0.2 * scale, centerY - 0.05 * scale);
      final rightHipJoint = Offset(centerX + 0.6 * scale, centerY - 0.05 * scale);
      final leftKneeJoint = Offset(centerX - 0.5 * scale, centerY + 1.3 * scale);
      final rightKneeJoint = Offset(centerX + 1.5 * scale, centerY + 0.7 * scale);
      final leftFootJoint = Offset(centerX - 0.65 * scale, centerY + 2.2 * scale);
      final rightFootJoint = Offset(centerX + 2.0 * scale, centerY + 0.8 * scale);

      _drawArticulatedBody(canvas,
        headCenter: headCenter,
        headRadius: headRadius,
        neckJoint: neckJoint,
        leftShoulderJoint: leftShoulderJoint,
        rightShoulderJoint: rightShoulderJoint,
        waistCenter: waistCenter,
        leftElbowJoint: leftElbowJoint,
        rightElbowJoint: rightElbowJoint,
        leftHandJoint: leftHandJoint,
        rightHandJoint: rightHandJoint,
        leftHipJoint: leftHipJoint,
        rightHipJoint: rightHipJoint,
        leftKneeJoint: leftKneeJoint,
        rightKneeJoint: rightKneeJoint,
        leftFootJoint: leftFootJoint,
        rightFootJoint: rightFootJoint,
        fillPaint: fillPaint,
        borderPaint: borderPaint,
        scale: scale,
      );
    }
  }

  void _drawPlankPose(Canvas canvas, double centerX, double centerY, double scale, Paint fillPaint, Paint borderPaint) {
    final headRadius = 0.26 * scale;

    final headCenter = Offset(centerX + 1.6 * scale, centerY + 0.2 * scale);
    final neckJoint = Offset(centerX + 1.3 * scale, centerY + 0.1 * scale);
    final leftShoulderJoint = Offset(centerX + 1.25 * scale, centerY + 0.2 * scale);
    final rightShoulderJoint = Offset(centerX + 1.25 * scale, centerY);
    final waistCenter = Offset(centerX - 1.0 * scale, centerY - 0.1 * scale);
    final leftElbowJoint = Offset(centerX + 0.5 * scale, centerY + 0.3 * scale);
    final rightElbowJoint = Offset(centerX + 0.5 * scale, centerY - 0.1 * scale);
    final leftHandJoint = Offset(centerX - 0.3 * scale, centerY + 0.4 * scale);
    final rightHandJoint = Offset(centerX - 0.3 * scale, centerY);
    final leftHipJoint = Offset(centerX - 0.95 * scale, centerY);
    final rightHipJoint = Offset(centerX - 0.95 * scale, centerY - 0.2 * scale);
    final leftKneeJoint = Offset(centerX - 1.6 * scale, centerY);
    final rightKneeJoint = Offset(centerX - 1.6 * scale, centerY - 0.2 * scale);
    final leftFootJoint = Offset(centerX - 2.2 * scale, centerY);
    final rightFootJoint = Offset(centerX - 2.2 * scale, centerY - 0.2 * scale);

    _drawArticulatedBody(canvas,
      headCenter: headCenter,
      headRadius: headRadius,
      neckJoint: neckJoint,
      leftShoulderJoint: leftShoulderJoint,
      rightShoulderJoint: rightShoulderJoint,
      waistCenter: waistCenter,
      leftElbowJoint: leftElbowJoint,
      rightElbowJoint: rightElbowJoint,
      leftHandJoint: leftHandJoint,
      rightHandJoint: rightHandJoint,
      leftHipJoint: leftHipJoint,
      rightHipJoint: rightHipJoint,
      leftKneeJoint: leftKneeJoint,
      rightKneeJoint: rightKneeJoint,
      leftFootJoint: leftFootJoint,
      rightFootJoint: rightFootJoint,
      fillPaint: fillPaint,
      borderPaint: borderPaint,
      scale: scale,
    );
  }

  void _drawStandingPose(Canvas canvas, double centerX, double centerY, double scale, Paint fillPaint, Paint borderPaint) {
    final headRadius = 0.32 * scale;

    final headCenter = Offset(centerX, centerY - 2.5 * scale);
    final neckJoint = Offset(centerX, centerY - 2.0 * scale);
    final leftShoulderJoint = Offset(centerX - 0.55 * scale, centerY - 1.95 * scale);
    final rightShoulderJoint = Offset(centerX + 0.55 * scale, centerY - 1.95 * scale);
    final waistCenter = Offset(centerX, centerY - 0.2 * scale);
    final leftElbowJoint = Offset(centerX - 0.65 * scale, centerY - 0.9 * scale);
    final rightElbowJoint = Offset(centerX + 0.65 * scale, centerY - 0.9 * scale);
    final leftHandJoint = Offset(centerX - 0.75 * scale, centerY + 0.1 * scale);
    final rightHandJoint = Offset(centerX + 0.75 * scale, centerY + 0.1 * scale);
    final leftHipJoint = Offset(centerX - 0.35 * scale, centerY - 0.15 * scale);
    final rightHipJoint = Offset(centerX + 0.35 * scale, centerY - 0.15 * scale);
    final leftKneeJoint = Offset(centerX - 0.4 * scale, centerY + 1.0 * scale);
    final rightKneeJoint = Offset(centerX + 0.4 * scale, centerY + 1.0 * scale);
    final leftFootJoint = Offset(centerX - 0.4 * scale, centerY + 2.2 * scale);
    final rightFootJoint = Offset(centerX + 0.4 * scale, centerY + 2.2 * scale);

    _drawArticulatedBody(canvas,
      headCenter: headCenter,
      headRadius: headRadius,
      neckJoint: neckJoint,
      leftShoulderJoint: leftShoulderJoint,
      rightShoulderJoint: rightShoulderJoint,
      waistCenter: waistCenter,
      leftElbowJoint: leftElbowJoint,
      rightElbowJoint: rightElbowJoint,
      leftHandJoint: leftHandJoint,
      rightHandJoint: rightHandJoint,
      leftHipJoint: leftHipJoint,
      rightHipJoint: rightHipJoint,
      leftKneeJoint: leftKneeJoint,
      rightKneeJoint: rightKneeJoint,
      leftFootJoint: leftFootJoint,
      rightFootJoint: rightFootJoint,
      fillPaint: fillPaint,
      borderPaint: borderPaint,
      scale: scale,
    );
  }

  @override
  bool shouldRepaint(GuideSkeletonPainter oldDelegate) {
    return oldDelegate.poseState != poseState ||
        oldDelegate.exerciseName != exerciseName ||
        oldDelegate.userPose != userPose ||
        oldDelegate.isMatching != isMatching ||
        oldDelegate.userGender != userGender;
  }
}