import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart' as stripe; // ✅ Prefix applied
import 'dart:io' show Platform;
import 'booking_details_screen.dart'; 

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  // 💳 STRIPE PAYMENT LOGIC
  Future<void> _processPayment(BuildContext context, Map<String, dynamic> booking) async {
    final bookingId = booking['id'];

    try {
      // 1. Initialize the Payment Sheet using the 'stripe' prefix
      // This prevents the conflict with Material's Card widget
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          merchantDisplayName: 'PetCare App',
          paymentIntentClientSecret: booking['stripe_payment_intent_id'] ?? 'pi_mock_secret',
        ),
      );

      // 2. Present the Stripe UI
      await stripe.Stripe.instance.presentPaymentSheet();

      // 3. Update Supabase on Success
      await Supabase.instance.client.from('bookings').update({
        'status': 'confirmed',
        'payment_status': 'paid',
      }).eq('id', bookingId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('parent_id', userId ?? ''), 
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) return const Center(child: Text("No booking requests yet."));

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final String status = (booking['status'] ?? 'pending').toString().toLowerCase();

              return Card( // ✅ Works now! No longer ambiguous
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookingDetailsScreen(bookingId: booking['id'])),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                    ),
                    title: Text("Service #${booking['id'].toString().substring(0, 5)}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status.toUpperCase(), 
                          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                        if (booking['total_amount'] != null)
                          Text("Price: \$${booking['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: _buildTrailingWidget(context, booking),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, Map<String, dynamic> booking) {
    // Standardizing status check to lowercase for reliability
    final String status = (booking['status'] ?? 'pending').toString().toLowerCase();

    if (status == 'quoted') {
      return ElevatedButton(
        onPressed: () => _processPayment(context, booking),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        child: const Text("Pay"),
      );
    }

    if (status == 'confirmed' || status == 'started') {
      return ElevatedButton(
        onPressed: () {
          if (!kIsWeb && Platform.isWindows) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tracking only on Android/iOS")));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailsScreen(bookingId: booking['id'])));
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        child: const Text("Track"),
      );
    }

    return Text(
      status == 'pending' ? "Awaiting Quote" : "Closed",
      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': case 'accepted': return Colors.green;
      case 'quoted': return Colors.orange;
      case 'started': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey; 
    }
  }

  IconData _getStatusIcon(String status) {
    if (['confirmed', 'accepted', 'started'].contains(status)) return Icons.check_circle;
    if (status == 'quoted') return Icons.payment;
    if (status == 'rejected') return Icons.cancel;
    return Icons.hourglass_empty;
  }
}