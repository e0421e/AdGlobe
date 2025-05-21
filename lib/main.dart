// test
import 'package:flutter/material.dart';
import 'widgets/ad_sphere.dart';

void main() {
  runApp(const DigitalAdSphereApp());
}

class DigitalAdSphereApp extends StatelessWidget {
  const DigitalAdSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdGlobe',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 改成白色背景
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Scaffold(
        body: Center(
          child: AdSphere(),
        ),
      ),
    );
  }
}
