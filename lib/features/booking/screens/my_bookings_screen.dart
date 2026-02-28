import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🛡️ Correctly identify the current logged-in user
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 📡 FIX: Changed 'user_id' to 'parent_id' to match your schema
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('parent_id', userId ?? ''), 
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text("You haven't booked any services yet."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final status = booking['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  ),
                  title: Text("Service Request #${booking['id'].toString().substring(0, 5)}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${status.toUpperCase()}", 
                        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                      if (booking['booking_date'] != null)
                        Text("Date: ${booking['booking_date'].toString().split('T')[0]}"),
                    ],
                  ),
                  trailing: _buildTrailingWidget(context, status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🛡️ Safety check for Live Tracking to prevent Windows crash
  Widget _buildTrailingWidget(BuildContext context, String status) {
    if (status == 'confirmed') {
      return ElevatedButton(
        onPressed: () {
          // Check if running on Windows to avoid the plugin error
          if (!kIsWeb && Platform.isWindows) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Maps/Tracking only available on Android/iOS")),
            );
          } else {
            // Navigate to your Live Tracking Screen here
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        child: const Text("Track"),
      );
    }
    return Text(
      status == 'pending' ? "Awaiting Response" : "Closed",
      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'accepted': return Colors.green; // Supporting both terms
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange; // Pending
    }
  }

  IconData _getStatusIcon(String status) {
    if (status == 'confirmed' || status == 'accepted') return Icons.check_circle;
    if (status == 'rejected') return Icons.cancel;
    return Icons.hourglass_empty;
  }
}