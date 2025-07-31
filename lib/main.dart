import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/config/firebase_options.dart';
import 'core/config/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: FreelanceFlowApp(),
    ),
  );
}

class FreelanceFlowApp extends ConsumerWidget {
  const FreelanceFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'FreelanceFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}