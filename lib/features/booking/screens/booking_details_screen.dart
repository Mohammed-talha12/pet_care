import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('id', bookingId)
            .map((list) => list.first),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!;
          final status = data['status'];
          final providerId = data['provider_id'];
          final isProvider = currentUserId == providerId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(status),
                const SizedBox(height: 20),
                
                if (status == 'pending') ...[
                  const Text("Incoming Quotes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildQuoteList(context),
                ],

                if (status != 'pending') ...[
                  _buildTimelineStep("Request Sent", true),
                  _buildTimelineStep("Provider Confirmed", ["confirmed", "started", "completed"].contains(status)),
                  _buildTimelineStep("Service in Progress", ["started", "completed"].contains(status)),
                  _buildTimelineStep("Service Completed", status == "completed"),
                  
                  const SizedBox(height: 40),

                  if (isProvider) _buildProviderControls(context, status),

                  // ⭐ Updated: Logic to show Review Button
                  if (!isProvider && status == "completed") 
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.star_rate),
                        label: const Text("Leave a Review"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: () => _showReviewDialog(context, providerId),
                      ),
                    )
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // 📝 NEW: Review Dialog Logic
  void _showReviewDialog(BuildContext context, String? providerId) {
    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Rate the Service"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border, 
                    color: Colors.orange, 
                    size: 30
                  ),
                  onPressed: () => setState(() => selectedRating = index + 1),
                )),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: "Share your experience...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Later")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.from('reviews').insert({
                    'booking_id': bookingId,
                    'provider_id': providerId,
                    'parent_id': Supabase.instance.client.auth.currentUser!.id,
                    'rating': selectedRating,
                    'comment': commentController.text,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Review submitted! Thank you.")),
                    );
                  }
                } catch (e) {
                  debugPrint("Review Error: $e");
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  // --- EXISTING HELPERS ---

  Widget _buildQuoteList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('quotes')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final quotes = snapshot.data!;
        if (quotes.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Waiting for offers...")));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text("Offer: ${quote['price']}"),
                trailing: ElevatedButton(
                  onPressed: () => _hireProvider(context, quote['provider_id'], quote['price']),
                  child: const Text("Hire"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _hireProvider(BuildContext context, String providerId, String price) async {
    await Supabase.instance.client.from('bookings').update({
      'status': 'confirmed',
      'provider_id': providerId,
      'budget_range': price,
    }).eq('id', bookingId);
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await Supabase.instance.client.from('bookings').update({'status': newStatus}).eq('id', bookingId);
  }

  Widget _buildProviderControls(BuildContext context, String status) {
    if (status == 'confirmed') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
        onPressed: () => _updateStatus(context, 'started'),
        child: const Text("START SERVICE"),
      );
    } else if (status == 'started') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
        onPressed: () => _updateStatus(context, 'completed'),
        child: const Text("MARK AS COMPLETED"),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusHeader(String status) {
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: status == 'completed' ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status == 'completed' ? Colors.green : Colors.blue),
      ),
      child: Text("STATUS: ${status.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTimelineStep(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isDone ? Colors.black : Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}