import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'realtime_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final RealtimeService _realtimeService = RealtimeService();
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(0, 0);
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToLocation();
  }

  void _listenToLocation() {
    _subscription = _realtimeService
        .subscribeToLiveLocation(widget.bookingId)
        .listen((data) {
      if (data.isNotEmpty) {
        final location = data.first;
        final lat = location['latitude'];
        final lng = location['longitude'];

        setState(() {
          _currentPosition = LatLng(lat, lng);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPosition),
        );
      }
    });
  }

  Future<void> _startTracking() async {
    await _realtimeService.updateLiveLocation(widget.bookingId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: {
          Marker(
            markerId: const MarkerId("provider"),
            position: _currentPosition,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startTracking,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
