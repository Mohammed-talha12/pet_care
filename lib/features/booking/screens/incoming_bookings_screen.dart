import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomingBookingsScreen extends StatelessWidget {
  const IncomingBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('New Service Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 📡 Listen for pending bookings that need quotes
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('status', 'pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text("No new requests in your area."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text("📍 ${booking['location'] ?? 'Location not set'}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Client's Budget: ${booking['budget_range']}"),
                      Text("Date: ${booking['booking_date'].toString().split('T')[0]}"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple, 
                      foregroundColor: Colors.white
                    ),
                    onPressed: () => _showQuoteDialog(context, booking['id'], userId!),
                    child: const Text("Send Quote"), // Updated from "Accept"
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 📝 Logic to show the Price Quote Dialog
  void _showQuoteDialog(BuildContext context, String bookingId, String providerId) {
    final TextEditingController quoteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Your Price Quote"),
        content: TextField(
          controller: quoteController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Amount",
            prefixText: "₹ ",
            hintText: "Enter your offer",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () async {
              if (quoteController.text.isNotEmpty) {
                await _submitQuote(context, bookingId, providerId, quoteController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Submit Quote"),
          ),
        ],
      ),
    );
  }

  // 🔄 Insert the quote into the new 'quotes' table
  Future<void> _submitQuote(BuildContext context, String bookingId, String providerId, String amount) async {
    try {
      await Supabase.instance.client.from('quotes').insert({
        'booking_id': bookingId,
        'provider_id': providerId,
        'price': '₹$amount',
        'status': 'pending',
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote sent successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending quote: $e')),
        );
      }
    }
  }
}