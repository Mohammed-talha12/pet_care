import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/themes/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase (Simple Version)
  // We remove 'authOptions' wrapper and use the direct parameters
  await Supabase.initialize(
    url: 'https://ttqoucjiglwthflzocpq.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0cW91Y2ppZ2x3dGhmbHpvY3BxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNjY3MDcsImV4cCI6MjA4Nzc0MjcwN30.zXwViPZ4ctxD5MnLnqPnDsKaFafohuNvF91aZC8jcgM',
    // In many versions, you can simply omit the authOptions class 
    // if you don't need custom deep link logic right this second.
    // If you need the redirect, try: authCallbackUrlHostname: 'login-callback'
  );

  // 2. Initialize Stripe
  //Stripe.publishableKey = "pk_test_your_stripe_key_here"; 
  //await Stripe.instance.applySettings();

  // 3. Initialize Firebase
  try {
    await Firebase.initializeApp();
    final notificationService = NotificationService();
    await notificationService.initNotifications();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const MyApp());
}

// Global client for easy access
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(), 
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;
        return session != null ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}