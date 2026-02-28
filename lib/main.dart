import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/themes/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart'; // 👈 Import your Home Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ttqoucjiglwthflzocpq.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0cW91Y2ppZ2x3dGhmbHpvY3BxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNjY3MDcsImV4cCI6MjA4Nzc0MjcwN30.zXwViPZ4ctxD5MnLnqPnDsKaFafohuNvF91aZC8jcgM', 
  );

  runApp(const MyApp());
}

// Shortcut to access the Supabase client anywhere in the app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 🛡️ Logic to decide where the user starts
      home: const AuthGate(), 
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔍 This checks if a valid session exists in local storage
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is already logged in, skip LoginScreen
      return const HomeScreen(); 
    } else {
      // No session found, show LoginScreen
      return const LoginScreen();
    }
  }
}


