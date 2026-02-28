import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetListWidget extends StatelessWidget {
  const PetListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      // 🔄 Real-time stream: Listens for changes in the 'pets' table
      stream: Supabase.instance.client
          .from('pets')
          .stream(primaryKey: ['id'])
          .eq('owner_id', userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("No pets added yet. Click 'Add New Pet' to start!"),
          );
        }

        final pets = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.pets, color: Colors.purple)),
                title: Text(pet['name'] ?? 'Unknown Pet', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${pet['type']} • ${pet['breed']}"),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}