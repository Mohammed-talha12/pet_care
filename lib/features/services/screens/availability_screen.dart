import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  Set<DateTime> _availableDays = {}; 
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  // 📡 Fetch saved dates from Supabase using 'blocked_date' column
  Future<void> _fetchAvailability() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('provider_availability')
          .select('blocked_date') // ✅ Updated to match your schema
          .eq('provider_id', userId);

      setState(() {
        _availableDays = (data as List)
            .map((item) => DateTime.parse(item['blocked_date']))
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching availability: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔄 Toggle availability for a specific day
  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Normalize date to ignore time components
    final normalizedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dateString = normalizedDate.toIso8601String().split('T')[0];

    setState(() {
      _focusedDay = focusedDay;
    });

    try {
      final isAlreadyMarked = _availableDays.any((d) => isSameDay(d, normalizedDate));

      if (isAlreadyMarked) {
        // Remove from database
        await _supabase
            .from('provider_availability')
            .delete()
            .eq('provider_id', userId)
            .eq('blocked_date', dateString); // ✅ Updated column name
        
        setState(() => _availableDays.removeWhere((d) => isSameDay(d, normalizedDate)));
      } else {
        // Add to database
        await _supabase.from('provider_availability').insert({
          'provider_id': userId,
          'blocked_date': dateString, // ✅ Updated column name
        });
        
        setState(() => _availableDays.add(normalizedDate));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Schedule'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAvailability,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      // Highlights the days that exist in our 'blocked_date' table as Green (Available)
                      selectedDayPredicate: (day) => _availableDays.any((d) => isSameDay(d, day)),
                      onDaySelected: _onDaySelected,
                      onFormatChanged: (format) => setState(() => _calendarFormat = format),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: Colors.green, 
                          shape: BoxShape.circle
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2), 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 1)
                        ),
                        outsideDaysVisible: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildLegend(),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available, color: Colors.green[700]),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Tap dates to toggle your availability. Green dates show when you can be booked.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green, "Available"),
        const SizedBox(width: 30),
        _legendItem(Colors.grey[300]!, "Unavailable"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16, 
          height: 16, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}