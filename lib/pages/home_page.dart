import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartcarparking/pages/profile_page.dart';
import 'package:smartcarparking/pages/qr_code_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  final Completer<GoogleMapController> _controller = Completer();

  final List<Marker> mapCarSpots = [];

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(38.46169459870305, 27.213280941150565),
    zoom: 20,
  );

  LatLng sourceLoc = LatLng(38.46169459870305, 27.213280941150565);

  LatLng targetLoc = LatLng(38.4618703530931, 27.21302428048082);

  Map<PolylineId, Polyline> polylines = {};

  String googleKey = dotenv.env["GOOGLE_API_KEY"]!;

  Future<Uint8List> getImagesFromMarkers(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return (await frameInfo.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<Position> getUserLocation() async {
    await Geolocator.requestPermission()
        .then((value) => {})
        .onError((error, stackTrace) => {});

    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();

    updateLocation();

    packData();

    Timer.periodic(const Duration(seconds: 3), (timer) {
      checkParkingSpotsStatus();
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleKey,
        request: PolylineRequest(
              origin: PointLatLng(sourceLoc.latitude, sourceLoc.longitude), 
              destination: PointLatLng(targetLoc.latitude, targetLoc.longitude), 
              mode: TravelMode.driving,
        ),
    );

    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      debugPrint(result.errorMessage);
      return [];
    }
  }

  Future<void> generatePolyLineFromPoints(List<LatLng> polylineCoords) async {
    const id = PolylineId('polyline');

    final polyline = Polyline(
        polylineId: id,
        color: Colors.deepPurple,
        points: polylineCoords,
        width: 15);

    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<void> packData() async {
    await getUserLocation().then((value) async {
      final Uint8List personIcon =
          await getImagesFromMarkers('assets/images/person.png', 150);

      mapCarSpots.add(
        Marker(
          markerId: const MarkerId('13'),
          position: LatLng(value.latitude, value.longitude),
          icon: BitmapDescriptor.fromBytes(personIcon),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );

      sourceLoc = LatLng(value.latitude, value.longitude);
    });

    setState(() {});
  }

  void checkParkingSpotsStatus() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('carparkingspots').get();
    final carparkingspots = snapshot.docs;

    for (var spot in carparkingspots) {
      final spotIndex = mapCarSpots.indexWhere(
        (element) => element.markerId == MarkerId(spot['name']),
      );

      final currentSpot = spotIndex > -1 ? mapCarSpots[spotIndex] : null;

      if (currentSpot != null) {
        if (!spot['status']) {
          mapCarSpots.removeWhere(
              (element) => element.markerId == currentSpot.markerId);
        }
      } else {
        if (spot['status']) {
          final Uint8List carIcon =
              await getImagesFromMarkers('assets/images/car.png', 200);
          mapCarSpots.add(
            Marker(
              markerId: MarkerId(spot['name']),
              position: LatLng(spot['latitude'], spot['longitude']),
              icon: BitmapDescriptor.fromBytes(carIcon),
              infoWindow:
                  InfoWindow(title: spot['name'], snippet: 'Free to park!'),
              onTap: () {
                targetLoc = LatLng(spot['latitude'], spot['longitude']);

                onMarkerTap();
              },
            ),
          );
        }
      }
    }

    setState(() {});
  }

  Future<void> onMarkerTap() async {
    final coords = await fetchPolylinePoints();

    generatePolyLineFromPoints(coords);
  }

  updateLocation() {
    getUserLocation().then((value) async {
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(value.latitude, value.longitude),
        zoom: 30,
      );

      final GoogleMapController controller = await _controller.future;

      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      floatingActionButton: FloatingActionButton(
        onPressed: updateLocation,
        backgroundColor: Colors.deepPurple,
        child:
            const Icon(CupertinoIcons.location, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                onPressed: () {},
                icon: const Icon(CupertinoIcons.map, size: 40)),
            IconButton(
                onPressed: () async {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: user!.email)
                      .get();

                  if (snapshot.docs[0].data()['currentparkspot'] == '') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const QRScannerPage(),
                      ),
                    );
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CupertinoAlertDialog(
                            title: const Text('Status'),
                            content: const Text(
                                'You already have a park spot, leave from that park spot first!'),
                            actions: <Widget>[
                              CupertinoDialogAction(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        });
                  }
                },
                icon: const Icon(CupertinoIcons.qrcode, size: 40)),
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.person, size: 40)),
          ],
        ),
      ),
      body: SafeArea(
        child: GoogleMap(
          onTap: (x) {},
          initialCameraPosition: _initialCameraPosition,
          markers: Set<Marker>.of(mapCarSpots),
          polylines: Set<Polyline>.of(polylines.values),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
      ),
    );
  }
}
