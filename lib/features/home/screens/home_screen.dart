import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/screens/login_screen.dart'; 

// Profiles & Pets
import '../../profile/screens/pet_profile_screen.dart';
import '../../profile/screens/provider_profile_screen.dart';

// Services
import '../../services/screens/find_services_screen.dart';
import '../../services/screens/manage_services_screen.dart';
import '../../services/screens/availability_screen.dart';
import '../../services/screens/service_request_form.dart';

// Bookings & Tracking
import 'package:pet_care/features/booking/screens/incoming_bookings_screen.dart';
import 'package:pet_care/features/booking/screens/my_bookings_screen.dart';
import 'package:pet_care/features/realtime/live_tracking_screen.dart';

// Chat
import 'package:pet_care/features/chat/chat_screen.dart';

// ✅ NEW: Notifications Import
import '../../notifications/notification_screen.dart'; 

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
          // 🔔 Notifications Icon (Priority 2: Real-time Alerts)
          IconButton(
            icon: const Badge(
              label: Text('3'), // This can be made dynamic later with a Stream
              child: Icon(Icons.notifications_none),
            ),
            onPressed: () {
              // ✅ Navigates to your new Notification Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
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
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: role == 'pet_parent' 
            ? _buildParentDashboard(context, userId) 
            : _buildProviderDashboard(context, userId),
      ),
    );
  }

  // --- 🏠 PARENT DASHBOARD ---
  Widget _buildParentDashboard(BuildContext context, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetList(userId),
        const SizedBox(height: 25),
        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        _buildMenuCard(
          context,
          icon: Icons.pets,
          color: Colors.purple,
          title: "My Pet Profiles",
          subtitle: "Manage details and photos",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PetProfileScreen())),
        ),

        _buildMenuCard(
          context,
          icon: Icons.payment,
          color: Colors.green,
          title: "Payments & Invoices",
          subtitle: "Pay for services and view history",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen())),
        ),

        _buildMenuCard(
          context,
          icon: Icons.search,
          color: Colors.blue,
          title: "Find Services",
          subtitle: "Search for sitters or walkers",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindServicesScreen())),
        ),
        
        _buildMenuCard(
          context,
          icon: Icons.history,
          color: Colors.blueGrey,
          title: "My Bookings",
          subtitle: "Check status & message providers",
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
                bookingId: '11111111-1111-1111-1111-111111111111', 
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 🏥 PROVIDER DASHBOARD ---
  Widget _buildProviderDashboard(BuildContext context, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        _buildMenuCard(
          context,
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          title: "Earnings & Payments",
          subtitle: "Track completed jobs and payouts",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen())),
        ),

        _buildMenuCard(
          context,
          icon: Icons.event_available,
          color: Colors.redAccent,
          title: "My Availability",
          subtitle: "Manage your working calendar",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AvailabilityScreen())),
        ),

        _buildMenuCard(
          context,
          icon: Icons.calendar_today,
          color: Colors.blue,
          title: "Incoming Bookings",
          subtitle: "Review and quote new requests",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IncomingBookingsScreen())),
        ),

        _buildMenuCard(
          context,
          icon: Icons.list_alt,
          color: Colors.orange,
          title: "My Services",
          subtitle: "Update your offerings and rates",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageServicesScreen())),
        ),
      ],
    );
  }

  // --- 🐶 PET LIST HELPER ---
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
                          // ✅ Shows uploaded photo (Priority 2 Requirement)
                          backgroundImage: pet['image_url'] != null 
                              ? NetworkImage(pet['image_url']) 
                              : null,
                          child: pet['image_url'] == null 
                              ? const Icon(Icons.pets, color: Colors.purple) 
                              : null,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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