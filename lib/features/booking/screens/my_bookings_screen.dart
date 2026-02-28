import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 📡 Listen for bookings created by THIS parent
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId ?? ''),
        builder: (context, snapshot) {
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
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                  ),
                  title: Text("Service Request #${booking['id'].toString().substring(0, 5)}"),
                  subtitle: Text("Status: ${status.toUpperCase()}"),
                  trailing: Text(
                    status == 'pending' ? "Awaiting Response" : "Updated",
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'confirmed') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange; // Pending
  }

  IconData _getStatusIcon(String status) {
    if (status == 'confirmed') return Icons.check_circle;
    if (status == 'rejected') return Icons.cancel;
    return Icons.hourglass_empty;
  }
}