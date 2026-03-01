import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  // You would typically call a Supabase Edge Function or an external 
  // backend here to create a PaymentIntent for security.
  Future<void> makePayment(double amount, String currency) async {
    try {
      // 1. Create Payment Intent (Mocking the backend call here)
      // In a real app, your backend handles the 'client_secret' creation
      final paymentIntentData = await _createPaymentIntent(amount, currency);

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'PetCare Services',
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();
      
      print("Payment Successful!");
    } catch (e) {
      print("Payment Failed: $e");
    }
  }

  _createPaymentIntent(double amount, String currency) async {
    // This part MUST be done on a secure server/Edge Function
    // Sending secret keys from the app is a security risk.
    return {'client_secret': 'your_backend_generated_secret'};
  }
}