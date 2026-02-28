import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/screens/login_screen.dart'; 

import '../../profile/screens/add_pet_screen.dart';
import '../../services/screens/find_services_screen.dart';
import '../../services/screens/manage_services_screen.dart';
import '../../profile/screens/provider_profile_screen.dart';
import 'package:pet_care/features/booking/screens/incoming_bookings_screen.dart';
import 'package:pet_care/features/booking/screens/my_bookings_screen.dart';
import 'package:pet_care/features/services/screens/availability_screen.dart';

import 'package:pet_care/features/realtime/live_tracking_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String role = user?.userMetadata?['role'] ?? 'pet_parent';
    final String userId = user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Changed to scrollable for multiple pets
        padding: const EdgeInsets.all(20.0),
        child: role == 'pet_parent' 
            ? _buildParentDashboard(context, userId) 
            : _buildProviderDashboard(context),
      ),
    );
  }

  // --- 🏠 PARENT DASHBOARD ---
  Widget _buildParentDashboard(BuildContext context, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🐾 Multiple Pet Support List
        _buildPetList(userId),
        const SizedBox(height: 25),
        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildMenuCard(
          context,
          icon: Icons.add_circle_outline,
          color: Colors.purple,
          title: "Add New Pet",
          subtitle: "Create a profile for your pet",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPetScreen())),
        ),
        _buildMenuCard(
          context,
          icon: Icons.search,
          color: Colors.green,
          title: "Find Services",
          subtitle: "Search for sitters or walkers",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindServicesScreen())),
        ),
        _buildMenuCard(
          context,
          icon: Icons.history,
          color: Colors.blueGrey,
          title: "My Bookings",
          subtitle: "Check status of your requests",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen())),
        ),

_buildMenuCard(
  context,
  icon: Icons.location_on,
  color: Colors.red,
  title: "Live Tracking",
  subtitle: "Track your pet in real-time",
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const LiveTrackingScreen(
        bookingId: '123', // Replace with real booking id later
      ),
    ),
  ),
),

       
      ],
    );
  }

  // --- 🏥 PROVIDER DASHBOARD ---
  Widget _buildProviderDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildMenuCard(
          context,
          icon: Icons.calendar_today,
          color: Colors.blue,
          title: "Incoming Bookings",
          subtitle: "Manage your pending requests",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IncomingBookingsScreen())),
        ),
        _buildMenuCard(
          context,
          icon: Icons.person_pin,
          color: Colors.teal,
          title: "Professional Profile",
          subtitle: "Update bio & experience",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderProfileScreen())),
        ),
        _buildMenuCard(
          context,
          icon: Icons.list_alt,
          color: Colors.orange,
          title: "My Services",
          subtitle: "Update your offerings and rates",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageServicesScreen())),
        ),
        // Placeholder for Availability feature
        _buildMenuCard(
          context,
          icon: Icons.event_available,
          color: Colors.redAccent,
          title: "Availability",
          subtitle: "Manage your working calendar",
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const AvailabilityScreen())
          ),
        ),
      ],
    );
  }

  // --- 🐶 PET LIST HELPER (Multiple Pet Support) ---
  Widget _buildPetList(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("My Pets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('pets')
                .stream(primaryKey: ['id'])
                .eq('owner_id', userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
              final pets = snapshot.data ?? [];
              
              if (pets.isEmpty) return const Text("No pets added yet.");

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.purple.shade50,
                          backgroundImage: pet['image_url'] != null ? NetworkImage(pet['image_url']) : null,
                          child: pet['image_url'] == null ? const Icon(Icons.pets, color: Colors.purple) : null,
                        ),
                        const SizedBox(height: 4),
                        Text(pet['name'], style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
