import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/app_theme.dart';
import 'core/config/firebase_options.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

/// FreelanceFlow - A modern Flutter application for freelancers
/// 
/// Features:
/// - Daily Routine Tracker with Notifications
/// - Client Management System
/// - Project Management with Kanban boards
/// - Payment Tracking & Invoice Management
/// - Firebase Integration (Auth, Firestore, Storage, FCM)
/// - Material 3 Design with Glassmorphism
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: FreelanceFlowApp(),
    ),
  );
}

class FreelanceFlowApp extends StatelessWidget {
  const FreelanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
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