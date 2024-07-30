import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartcarparking/pages/home_page.dart';
import 'package:smartcarparking/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final user = FirebaseAuth.instance.currentUser;

  String qrCodeResult = "No QR Code";

  @override
  void initState() {
    super.initState();
    scanQRCode();
  }

  Future<void> scanQRCode() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
      status = await Permission.camera.status;
    }
    if (status.isGranted) {
      String qrResult = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);

      if (qrResult != '-1') {
        String name = qrResult;

        DocumentSnapshot vehicleDoc = await FirebaseFirestore.instance
            .collection('carparkingspots')
            .doc(name)
            .get();

        if (vehicleDoc.exists) {
          bool currentStatus = vehicleDoc['status'];

          if (!currentStatus) {
            setState(() {
              qrCodeResult = "This parking spot is full!";
            });
          } else {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user!.email)
                .get();

            String platenumber = snapshot.docs[0].data()['licenseplatenumber'];

            await FirebaseFirestore.instance
                .collection('carparkingspots')
                .doc(name)
                .update({
              'status': false,
              'currentcarplate': platenumber,
            });

            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user!.email)
                .get()
                .then((QuerySnapshot querySnapshot) {
              querySnapshot.docs.forEach((doc) {
                doc.reference.update({'currentparkspot': vehicleDoc['name']});
              });
            });

            setState(() {
              qrCodeResult = "Parking is done!";
            });
          }
        } else {
          setState(() {
            qrCodeResult = "Car spot is not found!";
          });
        }
      } else {
        setState(() {
          qrCodeResult = "Failed to scan QR code!";
        });
      }

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text('Status'),
              content: Text(qrCodeResult),
              actions: <Widget>[
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          });
    } else {
      setState(() {
        qrCodeResult = "Failed to access to camera!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              qrCodeResult,
              style: const TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.map, size: 40),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(CupertinoIcons.qrcode, size: 40),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.person, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
