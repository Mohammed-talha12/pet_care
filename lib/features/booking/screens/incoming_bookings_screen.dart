import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomingBookingsScreen extends StatelessWidget {
  const IncomingBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 📡 Listen for bookings assigned to THIS provider
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('provider_id', userId ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text("No booking requests yet."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final status = booking['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Service ID: ${booking['service_id']}"),
                  subtitle: Text("Status: ${status.toUpperCase()}"),
                  trailing: status == 'pending' 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _updateStatus(context, booking['id'], 'confirmed'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _updateStatus(context, booking['id'], 'rejected'),
                          ),
                        ],
                      )
                    : Text(status, style: TextStyle(color: _getStatusColor(status))),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔄 Update the booking status in Supabase
  Future<void> _updateStatus(BuildContext context, String bookingId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $newStatus!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'confirmed') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
  }
}