import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/task_provider.dart';
import 'providers/note_provider.dart';
import 'providers/pet_provider.dart';
import 'screens/splash_screen.dart';
import 'services/storage/local_storage_service.dart';
import 'services/notification_service.dart';

//flutter emulators --launch Medium_Phone_API_36.0
//flutter run -d emulator-5554
// flutter run -d Medium_Phone_API_36.0



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable Firestore offline persistence (limit cache to 100MB for better performance)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 100 * 1024 * 1024, // 100MB limit (was unlimited)
  );
  
  // Initialize LocalStorage (delta-t-auth)
  await LocalStorageService.init();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
      ],
      child: MaterialApp(
        title: 'Delta T',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
