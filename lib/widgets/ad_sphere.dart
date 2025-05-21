import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'bubble.dart';
import 'sphere_painter.dart';
import 'package:flutter/services.dart' show rootBundle;

class AdSphere extends StatefulWidget {
  const AdSphere({super.key});

  @override
  State<AdSphere> createState() => _AdSphereState();
}

class _AdSphereState extends State<AdSphere> {
  double rotationAngle = 0;
  final double bubbleRadius = 40;

  List<Bubble> bubbles = [];
  List<ui.Image> bubbleImages = [];

  final List<String> imagePaths = [
    'images/number-one.png',
    'images/number-two.png',
    'images/number-three.png',
    'images/four.png',
    'images/five.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    List<ui.Image> loadedImages = [];
    for (var path in imagePaths) {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final img = await decodeImageFromList(bytes);
      loadedImages.add(img);
    }

    setState(() {
      bubbleImages = loadedImages;
    });
  }

  List<Bubble> _generateBubbles(int count) {
    final double goldenAngle = pi * (3 - sqrt(5));
    List<Bubble> list = [];
    for (int i = 0; i < count; i++) {
      double y = 1 - (i / (count - 1)) * 2;
      double theta = (goldenAngle * i) % (2 * pi);
      double phi = acos(y);
      final image = bubbleImages[i % bubbleImages.length];
      list.add(Bubble(theta: theta, phi: phi, image: image));
    }
    return list;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      rotationAngle += details.delta.dx * 0.01;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxDiameter = (size.shortestSide) * 0.7;
    final radius = maxDiameter / 2;

    final sphereArea = 4 * pi * radius * radius;
    final bubbleArea = pi * bubbleRadius * bubbleRadius;
    final numBubbles = (sphereArea / bubbleArea * 0.8).round();

    if (bubbleImages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    bubbles = _generateBubbles(numBubbles);
    final canvasSize = Size(radius * 2 + bubbleRadius * 2, radius * 2 + bubbleRadius * 2);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      child: CustomPaint(
        size: canvasSize,
        painter: SpherePainter(
          bubbles: bubbles,
          rotationAngle: rotationAngle,
          radius: radius,
          bubbleRadius: bubbleRadius,
        ),
      ),
    );
  }
}
