import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRequestForm extends StatefulWidget {
  @override
  _ServiceRequestFormState createState() => _ServiceRequestFormState();
}

class _ServiceRequestFormState extends State<ServiceRequestForm> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // Form State and Controllers
  String? selectedPetId;
  String? selectedServiceId;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _instructionsController = TextEditingController();

  // Fetching your data from Supabase
  Future<List<Map<String, dynamic>>> _getPets() async {
    return await _supabase.from('pets').select();
  }

  Future<List<Map<String, dynamic>>> _getServices() async {
    return await _supabase.from('services').select();
  }

  // Helper: Combine Date and Time into one ISO String for Supabase
  DateTime get _combinedDateTime {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  // 2. Submitting the booking
  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || selectedPetId == null || selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('bookings').insert({
        'parent_id': userId,
        'pet_id': selectedPetId,
        'service_id': selectedServiceId,
        'booking_date': _combinedDateTime.toIso8601String(), // Final Date/Time
        'location': _locationController.text,
        'budget_range': _budgetController.text,
        'special_instructions': _instructionsController.text,
        'status': 'pending', // Initial status per database schema
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error submitting booking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request a Service")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🐾 Pet Selection Dropdown
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPets(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Pet"),
                  items: snapshot.data!.map((pet) => DropdownMenuItem(
                    value: pet['id'].toString(),
                    child: Text(pet['name']),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedPetId = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // 🛠️ Service Type Dropdown
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Service Type"),
                  items: snapshot.data!.map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(s['service_name']),
                  )).toList(),
                  onChanged: (val) => setState(() => selectedServiceId = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // 📅 Date Picker
            ListTile(
              title: Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today, color: Colors.blue),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2027),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),

            // ⏰ Time Picker
            ListTile(
              title: Text("Time: ${selectedTime.format(context)}"),
              trailing: const Icon(Icons.access_time, color: Colors.blue),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) setState(() => selectedTime = picked);
              },
            ),
            const Divider(),

            // 📍 Address, Budget, and Notes
            TextFormField(
              controller: _locationController, 
              decoration: const InputDecoration(labelText: "Location/Address", icon: Icon(Icons.map)),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: _budgetController, 
              decoration: const InputDecoration(labelText: "Budget Range (e.g. ₹500 - ₹1000)", icon: Icon(Icons.money)),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: _instructionsController, 
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Special Instructions", icon: Icon(Icons.note_add)),
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _submitBooking, 
              child: const Text("Send Request", style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}