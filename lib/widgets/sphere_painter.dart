import 'dart:math';
import 'package:flutter/material.dart';
import 'bubble.dart';

class SpherePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double rotationAngle;
  final double radius;
  final double bubbleRadius;

  SpherePainter({
    required this.bubbles,
    required this.rotationAngle,
    required this.radius,
    required this.bubbleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Colors.grey.withOpacity(0.3);
    canvas.drawCircle(center, radius, paint);

    for (var bubble in bubbles) {
      double theta = (bubble.theta + rotationAngle) % (2 * pi);
      double phi = bubble.phi;

      double x = radius * sin(phi) * cos(theta);
      double y = radius * sin(phi) * sin(theta);
      double z = radius * cos(phi);

      // ✅ 新增條件：只顯示 z > 0（也就是球體面向前方的部分）
      if (x < 0) continue;

      Offset pos = center + Offset(y, z);
      double depthFactor = (x + radius) / (2 * radius);
      double scale = 0.5 + 0.5 * depthFactor;
      double alpha = 0.3 + 0.7 * depthFactor;

      double imgSize = bubbleRadius * 2 * scale;
      Rect dstRect = Rect.fromCenter(center: pos, width: imgSize, height: imgSize);
      canvas.save();

      Path clipPath = Path()..addOval(dstRect);
      canvas.clipPath(clipPath);

      canvas.drawImageRect(
        bubble.image!,
        Rect.fromLTWH(0, 0, bubble.image!.width.toDouble(), bubble.image!.height.toDouble()),
        dstRect,
        Paint()..color = Colors.white.withOpacity(alpha),
      );

      canvas.restore();

    }

  }

  @override
  bool shouldRepaint(covariant SpherePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle;
  }
}
