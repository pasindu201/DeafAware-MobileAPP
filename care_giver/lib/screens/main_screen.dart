import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class TrackAllDriversPage extends StatefulWidget {
  const TrackAllDriversPage({Key? key}) : super(key: key);

  @override
  _TrackAllDriversPageState createState() => _TrackAllDriversPageState();
}

class _TrackAllDriversPageState extends State<TrackAllDriversPage> {
  GoogleMapController? _googleMapController;
  final DatabaseReference _driversLocationRef = FirebaseDatabase.instance
      .ref()
      .child("active_deafcare_users"); // Reference to the drivers' location data in Firebase
  Map<String, Marker> _markers = {};

  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _fetchAllDriversLocation();
  }

  Future<String?> readUserInfo(String uid) async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("deafcare_users").child(uid);
      final snapshot = await userRef.once();

      if (snapshot.snapshot.value != null) {
        var userData = snapshot.snapshot.value as Map;
        return userData["name"] as String?;
      } else {
        throw Exception("User data not found");
      }
    } catch (e) {
      print("Error reading user info: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load user info: $e")));
      return null;
    }
  }

  void _loadCustomIcons() async {
    try {
      _driverIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(20, 20)),
        'images/man.png',
      );
      // After loading the icon, ensure the markers are updated
      _fetchAllDriversLocation();
    } catch (e) {
      print("Error loading icons: $e");
    }
  }

  void _fetchAllDriversLocation() {
    _driversLocationRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final Map<String, Marker> updatedMarkers = {};
        for (var uid in data.keys) {
          final locationData = data[uid];
          final loc = locationData['l'] as List<dynamic>;
          final latitude = loc[0] as double;
          final longitude = loc[1] as double;
          final LatLng driverPosition = LatLng(latitude, longitude);

          // Fetch the user's name asynchronously
          final name = await readUserInfo(uid);

          // Create a marker for each driver
          final marker = Marker(
            markerId: MarkerId(uid), // Use the driver's UID as the marker ID
            position: driverPosition,
            infoWindow: InfoWindow(
              title: name ?? 'Unknown', // Use 'Unknown' if the name is not available
            ),
            icon: _driverIcon!,
            onTap: () {
              // Manually show InfoWindow on marker tap
              _googleMapController?.showMarkerInfoWindow(MarkerId(uid));
            },
          );

          updatedMarkers[uid] = marker; // Add the marker to the map
        }

        // Update the map with the new markers
        setState(() {
          _markers = updatedMarkers;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track your Students",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 5,
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.9271, 79.8612), // Center the map on a default location (e.g., Colombo)
          zoom: 10,
        ),
        markers: Set<Marker>.of(_markers.values), // Display all markers on the map
        myLocationEnabled: true,
      ),
    );
  }
}
