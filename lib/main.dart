import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_picker/map_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> mapController = Completer();
  CameraPosition cameraPosition =
      const CameraPosition(target: LatLng(33.6844, 73.0479), zoom: 14);
  MapPickerController mapPickerController = MapPickerController();

  final List<Marker> _marker = <Marker>[
    const Marker(
        markerId: MarkerId("1"),
        position: LatLng(33.6844, 73.0479),
        infoWindow: InfoWindow(title: "current"))
  ];

  Future<Position> currentLocation() async {
    await Geolocator.requestPermission()
        .then((value) => {})
        .onError((error, stackTrace) {
      throw "error: $error";
    });
    return await Geolocator.getCurrentPosition();
  }

  loadLocation() {
    setState(() {
      currentLocation().then((value) async {
        log("check_: ${value.latitude} and ${value.longitude}");
        _marker.add(
          Marker(
            markerId: const MarkerId("2"),
            position: LatLng(value.latitude, value.longitude),
            infoWindow: const InfoWindow(title: "Current Location"),
          ),
        );
        CameraPosition cameraPosition = CameraPosition(
            target: LatLng(value.latitude, value.longitude), zoom: 14);
        final GoogleMapController controller = await mapController.future;
        controller
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      });
    });
  }

  String lat = "", long = "", address = "";

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openAppSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> getAddressFromLatLong(double latitude, double longitude) async {
    List<Placemark> placemark =
        await placemarkFromCoordinates(latitude, longitude);
    print(placemark);
    Placemark placemark1 = placemark[0];
    setState(() {
      address =
          "${placemark1.street.toString()}, ${placemark1.locality.toString()}, ${placemark1.isoCountryCode.toString()}, ${placemark1.postalCode.toString()} ";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            MapPicker(
              iconWidget: Image.asset(
                "assets/image/location.jpg",
                height: 50,
                width: 30,
              ),
              mapPickerController: mapPickerController,
              child: GoogleMap(
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                initialCameraPosition: cameraPosition,
                onMapCreated: (GoogleMapController controller) async {
                  mapController.complete(controller);
                },
                onCameraMoveStarted: () {
                  mapPickerController.mapMoving!();
                },
                onCameraMove: (cameraPosition) {
                  this.cameraPosition = cameraPosition;
                  log("position: ${cameraPosition.target.toString()}");
                  getAddressFromLatLong(cameraPosition.target.latitude,
                      cameraPosition.target.longitude);
                },
                onCameraIdle: () async {
                  mapPickerController.mapFinishedMoving!();
                },
              ),
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.grey,
              ),
              child: Text(
                "Your Address: $address",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}


   /*const Text(
            "Latitute and Longitute",
            style: TextStyle(fontSize: 18),
          ),
          Text(
            "$lat $long",
            style: const TextStyle(fontSize: 18),
          ),
          const Text(
            "Address",
            style: TextStyle(fontSize: 18),
          ),
          Text(
            address,
            style: const TextStyle(fontSize: 18),
          ),
          ElevatedButton(
            onPressed: () async {
              Position position = await _determinePosition();
              print("check_: ${position.latitude}");
              getAddressFromLatLong(position);
              setState(() {
                lat = position.latitude.toString();
                long = position.longitude.toString();
              });
            },
            child: const Text("Get Address"),
          ),*/