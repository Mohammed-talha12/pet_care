import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/widgets/primary_button.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final providerId = service['provider_id'];

    return Scaffold(
      appBar: AppBar(title: Text(service['service_name'] ?? 'Service Details')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('service_providers')
            .select()
            .eq('id', providerId)
            .maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final providerData = snapshot.data;
          final bool isVerified = providerData?['is_verified'] ?? false; // 👈 Requirement
          final List<String> portfolio = List<String>.from(providerData?['portfolio_urls'] ?? []); // 👈 Requirement

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Price and Verification Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$${service['price']}/hr",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    if (isVerified)
                      const Chip(
                        avatar: Icon(Icons.verified, color: Colors.white, size: 16),
                        label: Text("Verified", style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                const Text("About the Provider", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Text(
                  providerData?['bio'] ?? "No bio provided.",
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 15),
                
                // 📊 Experience and Skills
                Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text("Experience: ${providerData?['experience_years'] ?? '0'} years"),
                  ],
                ),
                const SizedBox(height: 25),

                // 📸 Portfolio Gallery
                if (portfolio.isNotEmpty) ...[
                  const Text("Portfolio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolio.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(portfolio[index], width: 120, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                PrimaryButton(
                  text: "Book This Service",
                  onPressed: () => _handleBooking(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBooking(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    // 📅 Pick a date for the 'booking_date' column
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null) return;

    try {
      // 🚀 Inserting into the existing 'bookings' table
      await Supabase.instance.client.from('bookings').insert({
        'parent_id': userId, // From schema
        'provider_id': service['provider_id'], // From schema
        'service_id': service['id'], // From schema
        'booking_date': pickedDate.toIso8601String(), // From schema
        'status': 'pending', // From schema
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Booking Error: $e");
    }
  }
}