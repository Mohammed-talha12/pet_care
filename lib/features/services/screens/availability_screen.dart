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

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  // 📡 Fetch saved dates from Supabase
  Future<void> _fetchAvailability() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('provider_availability')
          .select('available_date')
          .eq('provider_id', userId);

      setState(() {
        _availableDays = (data as List)
            .map((item) => DateTime.parse(item['available_date']))
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Normalize date to ignore time components
    final normalizedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dateString = normalizedDate.toIso8601String().split('T')[0];

    setState(() {
      _focusedDay = focusedDay;
    });

    try {
      final isAlreadyAvailable = _availableDays.any((d) => isSameDay(d, normalizedDate));

      if (isAlreadyAvailable) {
        // Remove availability
        await Supabase.instance.client
            .from('provider_availability')
            .delete()
            .eq('provider_id', userId)
            .eq('available_date', dateString);
        
        setState(() => _availableDays.removeWhere((d) => isSameDay(d, normalizedDate)));
      } else {
        // Add availability
        await Supabase.instance.client.from('provider_availability').insert({
          'provider_id': userId,
          'available_date': dateString,
        });
        
        setState(() => _availableDays.add(normalizedDate));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not update date: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Schedule'),
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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => _availableDays.any((d) => isSameDay(d, day)),
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) => setState(() => _calendarFormat = format),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      // Customizing appearance for requirements
                      selectedDecoration: const BoxDecoration(
                        color: Colors.green, 
                        shape: BoxShape.circle
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3), 
                        shape: BoxShape.circle
                      ),
                      markersMaxCount: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLegend(),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blueGrey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Select dates when you are open to receiving pet care requests.",
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
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
        const SizedBox(width: 20),
        _legendItem(Colors.grey[300]!, "Unavailable"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}