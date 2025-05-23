import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // 新增 Google Fonts
import 'widgets/ad_sphere.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:adglobe/models/ModelProvider.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'amplifyconfiguration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();

  runApp(const DigitalAdSphereApp());
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider.instance)),
      // AmplifyStorageS3(),
    ]);
    await Amplify.configure(amplifyconfig);
    debugPrint('Amplify configured successfully');
  } catch (e) {
    debugPrint('Amplify configuration error: $e');
  }
}

class DigitalAdSphereApp extends StatelessWidget {
  const DigitalAdSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdGlobe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 改成白色背景
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.notoSansTcTextTheme(), // 使用 Noto Sans TC 字體
      ),
      home: const Scaffold(
        body: Center(
          child: AdSphere(),
        ),
      ),
    );
  }
}