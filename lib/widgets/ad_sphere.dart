import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

import 'bubble.dart';
import 'sphere_painter.dart';

class AdSphere extends StatefulWidget {
  const AdSphere({super.key});

  @override
  State<AdSphere> createState() => _AdSphereState();
}

class _AdSphereState extends State<AdSphere> {
  final double bubbleRadius = 40;
  List<Bubble> bubbles = [];
  List<ui.Image> bubbleImages = [];
  List<Map<String, dynamic>> ads = [];
  DateTime? _lastTapTime;
  double? radius;
  double? adjustedBubbleRadius;

  final List<String> imagePaths = [
    'images/number-one.png',
    'images/number-two.png',
    'images/number-three.png',
    'images/four.png',
    'images/five.png',
  ];

  vmath.Matrix4 rotationMatrix = vmath.Matrix4.identity();
  Offset? lastPanPos;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _fetchAds();
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

  Future<void> _fetchAds() async {
    try {
      final request = GraphQLRequest<String>(
        document: '''
          query ListAds {
            listAds {
              items {
                id
                title
                description
                createdAt
              }
            }
          }
        ''',
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;
      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final items = data['listAds']['items'] as List<dynamic>? ?? [];
        setState(() {
          ads = items.cast<Map<String, dynamic>>();
        });
        if (items.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目前沒有廣告資料')),
          );
        }
      } else {
        print('查詢廣告失敗: ${response.errors}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法載入廣告資料，請稍後再試')),
          );
        }
      }
    } catch (e) {
      print('查詢廣告時發生錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法載入廣告資料，請檢查網路或資料格式')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchAdById(String id) async {
    try {
      final request = GraphQLRequest<String>(
        document: '''
          query GetAd(\$id: ID!) {
            getAd(id: \$id) {
              id
              title
              description
              createdAt
            }
          }
        ''',
        variables: {'id': id},
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;
      if (response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        if (data['getAd'] != null) {
          return data['getAd'] as Map<String, dynamic>;
        } else {
          print('廣告 ID $id 不存在');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('廣告 ID $id 不存在')),
            );
          }
          return null;
        }
      } else {
        print('查詢廣告詳情失敗: ${response.errors}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法載入廣告詳情，請稍後再試')),
          );
        }
        return null;
      }
    } catch (e) {
      print('查詢廣告詳情時發生錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法載入廣告詳情，請檢查網路或資料格式')),
        );
      }
      return null;
    }
  }

  List<Bubble> _generateBubbles(int count) {
    final double goldenRatio = (1 + sqrt(5)) / 2;
    final double goldenAngle = 2 * pi * (1 - 1 / goldenRatio);

    List<Bubble> list = [];
    for (int i = 0; i < count; i++) {
      double y = 1 - (i + 0.5) * 2 / count;
      double radius = sqrt(1 - y * y);
      double theta = (goldenAngle * i) % (2 * pi);
      double x = cos(theta) * radius;
      double z = sin(theta) * radius;
      double phi = acos(y);

      final image = bubbleImages[i % bubbleImages.length];
      final adId = ads.isNotEmpty ? ads[i % ads.length]['id'] : 'default-$i';
      list.add(Bubble(theta: theta, phi: phi, image: image, id: adId));
    }
    return list;
  }

  void _onPanStart(DragStartDetails details) {
    lastPanPos = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (lastPanPos == null) return;

    final currentPos = details.localPosition;
    final delta = currentPos - lastPanPos!;
    lastPanPos = currentPos;

    final dx = delta.dx;
    final dy = delta.dy;

    final vmath.Vector3 axis = vmath.Vector3(-dy, dx, 0).normalized();
    final angle = delta.distance * 0.005;

    setState(() {
      final rot = vmath.Matrix4.identity()..rotate(axis, angle);
      rotationMatrix = rot * rotationMatrix;
    });
  }

  void _onTapUp(TapUpDetails details) async {
    // 防抖：確保短時間內只處理一次點擊
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 500) {
      return;
    }
    _lastTapTime = now;

    if (radius == null || adjustedBubbleRadius == null) return;

    final canvasSize = Size(
      radius! * 2 + adjustedBubbleRadius! * 2,
      radius! * 2 + adjustedBubbleRadius! * 2,
    );
    final painter = SpherePainter(
      bubbles: bubbles,
      rotationMatrix: rotationMatrix,
      radius: radius!,
      bubbleRadius: adjustedBubbleRadius!,
    );

    final tappedBubble = painter.findTappedBubble(details.localPosition, canvasSize);
    if (tappedBubble != null) {
      final ad = await _fetchAdById(tappedBubble.id);
      if (ad != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(ad['title'] ?? '無標題'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad['description'] ?? '無描述'),
                const SizedBox(height: 8),
                Text('建立時間: ${ad['createdAt'] ?? '未知'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('關閉'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxDiameter = (size.shortestSide) * 0.8;
    radius = maxDiameter / 2;

    final int numBubbles = 150;
    final approxDistance = radius! * sqrt(6 * pi / numBubbles);
    adjustedBubbleRadius = approxDistance * 0.4;

    if (bubbleImages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    bubbles = _generateBubbles(numBubbles);
    final canvasSize = Size(radius! * 2 + adjustedBubbleRadius! * 2, radius! * 2 + adjustedBubbleRadius! * 2);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onTapUp: _onTapUp, // 改用 onTapUp
      child: CustomPaint(
        size: canvasSize,
        painter: SpherePainter(
          bubbles: bubbles,
          rotationMatrix: rotationMatrix,
          radius: radius!,
          bubbleRadius: adjustedBubbleRadius!,
        ),
      ),
    );
  }
}