import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Firebase reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child(
    'loadcell',
  );

  // Add this line to store the stream subscription
  StreamSubscription<DatabaseEvent>? _dataSubscription;

  // Default location (will be updated from Firebase)
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();

    // Listen for real-time updates
    _dataSubscription = _databaseRef.onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;

        // Check if location data exists in Firebase
        if (data['latitude'] != null && data['longitude'] != null) {
          setState(() {
            _latitude = double.parse(data['latitude'].toString());
            _longitude = double.parse(data['longitude'].toString());
            _hasLocation = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: const Text(
          "Location Tracker",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 53, 73),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body:
          _hasLocation
              ? FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_latitude, _longitude),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.payloadsurveillanceapp',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_latitude, _longitude),
                        width: 80,
                        height: 80,
                        child: const Icon(
                          // Changed from 'builder' to 'child'
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : const Center(
                child: Text(
                  'Waiting for location data...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
    );
  }
}
