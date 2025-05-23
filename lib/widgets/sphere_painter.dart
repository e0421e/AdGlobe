import 'dart:math';
import 'package:flutter/material.dart';
import 'bubble.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class SpherePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final vmath.Matrix4 rotationMatrix;
  final double radius;
  final double bubbleRadius;

  SpherePainter({
    required this.bubbles,
    required this.rotationMatrix,
    required this.radius,
    required this.bubbleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Colors.grey.withOpacity(0.3);
    canvas.drawCircle(center, radius, paint);

    for (var bubble in bubbles) {
      double theta = bubble.theta;
      double phi = bubble.phi;

      final vmath.Vector3 position = vmath.Vector3(
        sin(phi) * cos(theta),
        sin(phi) * sin(theta),
        cos(phi),
      )..scale(radius);

      final rotated = rotationMatrix.transform3(position);

      if (rotated.z < 0) continue;

      final pos = center + Offset(rotated.x, rotated.y);
      final depthFactor = (rotated.z + radius) / (2 * radius);
      final scale = 0.5 + 0.5 * depthFactor;
      final alpha = 0.3 + 0.7 * depthFactor;

      double imgSize = bubbleRadius * 2 * scale;
      Rect dstRect = Rect.fromCenter(center: pos, width: imgSize, height: imgSize);

      canvas.save();
      canvas.clipPath(Path()..addOval(dstRect));
      canvas.drawImageRect(
        bubble.image!,
        Rect.fromLTWH(0, 0, bubble.image!.width.toDouble(), bubble.image!.height.toDouble()),
        dstRect,
        Paint()..color = Colors.white.withOpacity(alpha),
      );
      canvas.restore();
    }
  }

  // 檢查點擊是否在某個泡泡內
  Bubble? findTappedBubble(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var bubble in bubbles) {
      double theta = bubble.theta;
      double phi = bubble.phi;

      final vmath.Vector3 position3D = vmath.Vector3(
        sin(phi) * cos(theta),
        sin(phi) * sin(theta),
        cos(phi),
      )..scale(radius);

      final rotated = rotationMatrix.transform3(position3D);

      if (rotated.z < 0) continue;

      final pos = center + Offset(rotated.x, rotated.y);
      final depthFactor = (rotated.z + radius) / (2 * radius);
      final scale = 0.5 + 0.5 * depthFactor;
      double imgSize = bubbleRadius * 2 * scale;

      Rect dstRect = Rect.fromCenter(center: pos, width: imgSize, height: imgSize);

      if (dstRect.contains(position)) {
        return bubble;
      }
    }
    return null;
  }

  @override
  bool? hitTest(Offset position) {
    // 僅檢查是否點擊在畫布內，具體泡泡檢測交給 GestureDetector
    final size = Size(radius * 2 + bubbleRadius * 2, radius * 2 + bubbleRadius * 2);
    final center = Offset(size.width / 2, size.height / 2);
    final distance = (position - center).distance;
    return distance <= radius + bubbleRadius; // 點擊在球體範圍內
  }

  @override
  bool shouldRepaint(covariant SpherePainter oldDelegate) {
    return oldDelegate.rotationMatrix != rotationMatrix;
  }
}