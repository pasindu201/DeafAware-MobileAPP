import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../assistants/assistant_methods.dart';
import '../global/global.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(6.42796133580664, 82.085749655962),
    zoom: 14.4746,
  );

  var geocoder = Geolocator();

  LocationPermission? _locationPermission;

  String statusText = "Now Offline";
  Color buttonColor = Colors.grey;
  bool isDriverActive = false;

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateDriverPossion() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(
        userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<void> readCurrentDriverInformation() async {
    currentUser = firebaseAuth.currentUser;
    FirebaseDatabase.instance
        .ref()
        .child("deafcare_users")
        .child(currentUser!.uid)
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        onlineUsererData.id = (snap.snapshot.value as Map)["id"];
        onlineUsererData.name = (snap.snapshot.value as Map)["name"];
        onlineUsererData.phone = (snap.snapshot.value as Map)["phone"];
        onlineUsererData.email = (snap.snapshot.value as Map)["email"];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    readCurrentDriverInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          padding: const EdgeInsets.only(top: 40),
          mapType: MapType.normal,
          myLocationEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;
            locateDriverPossion();
          },
        ),
        // UI for online / offline driver
        if (statusText != "Now Online")
          Container(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            color: Colors.black87,
          ),
        // Button for online/offline driver
        Positioned(
          top: statusText != "Now Online"
              ? MediaQuery.of(context).size.height * 0.45
              : 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (!isDriverActive) {
                    setDriverOnline();
                    updateDriverLocationInRealTime();

                    setState(() {
                      statusText = "Now Online";
                      isDriverActive = true;
                      buttonColor = Colors.transparent;
                    });
                  } else {
                    setDriverOffline();
                    setState(() {
                      statusText = "Now OffLine";
                      isDriverActive = false;
                      buttonColor = Colors.grey;
                    });
                    Fluttertoast.showToast(msg: "You are Offline now");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: statusText != "Now Online"
                    ? Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.phonelink_ring,
                        color: Colors.white,
                        size: 26,
                      ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Future<void> setDriverOnline() async {
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = pos;
    Geofire.initialize("active_deafcare_users");
    Geofire.setLocation(currentUser!.uid, userCurrentPosition!.latitude, userCurrentPosition!.longitude);

    DatabaseReference ref = FirebaseDatabase.instance.ref().child("deafcare_users").child(currentUser!.uid).child("newRidewStatus");
    ref.set("idle");
    ref.onValue.listen((event) {});
  }

  void updateDriverLocationInRealTime() {
    streamSubscriptionPosition =
        Geolocator.getPositionStream().listen((Position position) {
      if (isDriverActive) {
        Geofire.setLocation(currentUser!.uid, userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      }

      LatLng latLng = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

  void setDriverOffline() {
    Geofire.removeLocation(currentUser!.uid);
    DatabaseReference? ref = FirebaseDatabase.instance.ref().child("deafcare_users").child(currentUser!.uid).child("newRidewStatus");

    ref.onDisconnect();
    ref.remove();
    ref = null;
    
  }
}
