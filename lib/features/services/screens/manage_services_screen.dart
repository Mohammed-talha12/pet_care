import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../../auth/widgets/primary_button.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  // Define the required service categories
  final List<String> _availableServices = [
    'Pet Sitting',
    'Dog Walking',
    'Pet Boarding',
    'Pet Grooming',
    'Daycare',
    'Pet Taxi'
  ];

  // Map to store controllers for each service's price
  final Map<String, TextEditingController> _priceControllers = {};
  // Set to track which services are currently enabled/selected
  final Set<String> _selectedServices = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingServices();
  }

  // 📡 Load existing services from Supabase to pre-fill the UI
  Future<void> _fetchExistingServices() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      final data = await Supabase.instance.client
          .from('services')
          .select()
          .eq('provider_id', user?.id ?? '');

      for (var item in data) {
        final name = item['service_name'];
        final price = item['price'].toString();
        
        setState(() {
          _selectedServices.add(name);
          _priceControllers[name] = TextEditingController(text: price);
        });
      }
    } catch (e) {
      debugPrint("Error fetching services: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔄 Toggle a service on/off
  void _toggleService(bool? value, String serviceName) {
    setState(() {
      if (value == true) {
        _selectedServices.add(serviceName);
        _priceControllers[serviceName] = TextEditingController(text: '20.0');
      } else {
        _selectedServices.remove(serviceName);
        // We don't delete immediately; wait for "Save" button or delete call
      }
    });
  }

  Future<void> _saveAllServices() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      // 1. Prepare data for selected services
      final updates = _selectedServices.map((service) {
        return {
          'provider_id': user?.id,
          'service_name': service,
          'price': double.tryParse(_priceControllers[service]?.text ?? '0') ?? 0.0,
        };
      }).toList();

      // 2. Clear old services and upsert new ones (or handle deletions)
      // Note: For a simpler flow, we delete all for this provider then re-insert
      await Supabase.instance.client
          .from('services')
          .delete()
          .eq('provider_id', user?.id ?? '');

      if (updates.isNotEmpty) {
        await Supabase.instance.client.from('services').insert(updates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Services updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Services')),
      body: _isLoading && _selectedServices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _availableServices.length,
                    itemBuilder: (context, index) {
                      final service = _availableServices[index];
                      final isSelected = _selectedServices.contains(service);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                title: Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
                                value: isSelected,
                                onChanged: (val) => _toggleService(val, service),
                                activeColor: Colors.teal,
                              ),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  child: CustomTextField(
                                    controller: _priceControllers[service]!,
                                    label: "Price per Hour (\$)",
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : PrimaryButton(text: "Save All Services", onPressed: _saveAllServices),
                ),
              ],
            ),
    );
  }
}