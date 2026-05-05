import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/cache/hive_cache.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar appearance
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  await FirebaseInitializer().initialize();

  // Initialize cache
  await HiveCache().initialize();

  runApp(const HuitStudentApp());
}
