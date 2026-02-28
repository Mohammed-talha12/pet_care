import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_care/features/services/screens/service_details_screen.dart';

class FindServicesScreen extends StatelessWidget {
  const FindServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Pet Services'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🔄 Use a select with a join to get provider details (name & verification)
        stream: Supabase.instance.client
            .from('services')
            .stream(primaryKey: ['id'])
            .order('price', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No services available yet."));
          }

          final services = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              
              // Note: In a real app, you'd perform a join or a second fetch 
              // to get 'is_verified' from the 'service_providers' table.
              // Assuming 'is_verified' is part of the service map for this UI:
              final bool isVerified = service['is_verified'] ?? false;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsScreen(service: service),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // 📸 Provider Image Placeholder
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        
                        // 📝 Service Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    service['service_name'] ?? 'General Care',
                                    style: const TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  // 🛡️ THE VERIFICATION BADGE
                                  if (isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.verified, color: Colors.blue, size: 18),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Provider ID: ${service['provider_id'].toString().substring(0, 8)}...",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // 💰 Price Tag
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${service['price']}",
                              style: const TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: Color(0xFF6C63FF)
                              ),
                            ),
                            const Text("/hr", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}