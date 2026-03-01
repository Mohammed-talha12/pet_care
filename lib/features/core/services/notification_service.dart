import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initNotifications() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the Token
      String? token = await _fcm.getToken();
      
      if (token != null) {
        // 3. Save to Supabase Profile
        await _saveTokenToDatabase(token);
      }
    }

    // 4. Handle Foreground Messages (while app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        // You can show a custom snackbar or local notification here
      }
    });
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    }
  }
}