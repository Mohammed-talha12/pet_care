import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RealtimeService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// 🔹 Get Current Location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// 🔹 Update Live Location in Supabase
  Future<void> updateLiveLocation(String bookingId) async {
    final position = await getCurrentLocation();

    await supabase.from('live_tracking').upsert({
      'booking_id': bookingId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// 🔹 Subscribe to Live Location Updates
  Stream<List<Map<String, dynamic>>> subscribeToLiveLocation(
      String bookingId) {
    return supabase
        .from('live_tracking')
        .stream(primaryKey: ['booking_id'])
        .eq('booking_id', bookingId);
  }

  /// 🔹 Add Service Activity Log (Walk, Meal, etc.)
  Future<void> addActivityLog({
    required String bookingId,
    required String activityType,
    required String notes,
  }) async {
    await supabase.from('activity_logs').insert({
      'booking_id': bookingId,
      'activity_type': activityType,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
