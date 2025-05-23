import 'dart:ui' as ui;

class Bubble {
  final double theta;
  final double phi;
  final ui.Image image;
  final String id; // 新增廣告 ID

  Bubble({
    required this.theta,
    required this.phi,
    required this.image,
    required this.id,
  });
}