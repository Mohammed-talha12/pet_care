import 'dart:async';
import 'dart:io' show Platform; // 👈 Needed for platform checks
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  
  // 📍 Default to a neutral location (e.g., center of a city) until data arrives
  LatLng _currentPosition = const LatLng(37.42796133580664, -122.085749655962); 
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Only listen if we are on a supported platform
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _listenToLocation();
    }
  }

  void _listenToLocation() {
    _subscription = _realtimeService
        .subscribeToLiveLocation(widget.bookingId)
        .listen((data) {
      if (data.isNotEmpty) {
        final location = data.first;
        final lat = location['latitude'] as double;
        final lng = location['longitude'] as double;

        if (mounted) {
          setState(() {
            _currentPosition = LatLng(lat, lng);
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentPosition),
          );
        }
      }
    });
  }

  Future<void> _startTracking() async {
    // 🛡️ Guard against non-mobile execution
    if (!kIsWeb && Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GPS tracking requires an Android or iOS device.")),
      );
      return;
    }
    await _realtimeService.updateLiveLocation(widget.bookingId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🚧 The "Safety Gate": Check if platform is supported
    final bool isSupported = kIsWeb || Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
      ),
      body: !isSupported 
        ? _buildUnsupportedPlatformUI() 
        : GoogleMap(
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
                infoWindow: const InfoWindow(title: "Service Provider"),
              ),
            },
          ),
      floatingActionButton: isSupported ? FloatingActionButton(
        onPressed: _startTracking,
        child: const Icon(Icons.my_location),
      ) : null,
    );
  }

  Widget _buildUnsupportedPlatformUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.computer, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Desktop Not Supported",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Maps and Live GPS tracking are only available on mobile devices (Android & iOS).",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            )
          ],
        ),
      ),
    );
  }
}

