import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth_screen.dart';
import 'main_navigation.dart';
import 'firebase_options.dart';
import 'services/food_ai_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

const Color kPrimaryColor = Color(0xFF4CAF50);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first
  try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Error loading environment variables: $e');
    // Continue without .env file for development
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check
    await FirebaseAppCheck.instance.activate(
      // For debug/development, use debug provider
      androidProvider: AndroidProvider.debug,
      // For production, you'll want to use AndroidProvider.playIntegrity
    );

    print('Firebase and App Check initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  print('Google ML Kit will initialize automatically when needed');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: kPrimaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}