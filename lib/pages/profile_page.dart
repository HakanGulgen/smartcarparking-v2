import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartcarparking/auth/main_page.dart';
import 'package:smartcarparking/pages/home_page.dart';
import 'package:smartcarparking/pages/qr_code_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  String email = '', firstname = '', lastname = '', licenseplatenumber = '';

  bool isUserHasSpot = false;
  String currentparkspot = '';

  @override
  void initState() {
    super.initState();
    loadDetails();
    checkCarParkSpot();
  }

  void checkCarParkSpot() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user!.email)
        .get();

    if (snapshot.docs[0].data()['currentparkspot'] != '') {
      isUserHasSpot = true;

      currentparkspot = snapshot.docs[0].data()['currentparkspot'];
    } else {
      isUserHasSpot = false;

      currentparkspot = '';
    }
  }

  void loadDetails() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user!.email)
        .get();

    setState(() {
      email = snapshot.docs[0].data()['email'];
      firstname = snapshot.docs[0].data()['firstname'];
      lastname = snapshot.docs[0].data()['lastname'];
      licenseplatenumber = snapshot.docs[0].data()['licenseplatenumber'];
    });
  }

  void doneLeavingCarSpot() async {
    await FirebaseFirestore.instance
        .collection('carparkingspots')
        .where('name', isEqualTo: currentparkspot)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.update({'status': true});
        doc.reference.update({'currentcarplate': ''});
      });
    });

    await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user!.email)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.update({'currentparkspot': ''});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 70,
              backgroundImage: AssetImage('assets/images/person.png'),
            ),
            const SizedBox(height: 20),
            itemProfile('Name', firstname, CupertinoIcons.text_alignleft),
            const SizedBox(height: 10),
            itemProfile('E-Mail', email, CupertinoIcons.mail),
            const SizedBox(height: 10),
            itemProfile('License Plate Number', licenseplatenumber,
                CupertinoIcons.car_detailed),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CupertinoAlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure?'),
                          actions: <Widget>[
                            CupertinoDialogAction(
                              onPressed: () {
                                FirebaseAuth.instance.signOut();

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const MainPage(),
                                  ),
                                );
                              },
                              child: const Text('Yes'),
                            ),
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('No'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Colors.red, // Set button color to red
                  ),
                  child: const Icon(
                    CupertinoIcons.square_arrow_left,
                    color: Colors.white,
                    size: 40,
                  )),
            ),
            const SizedBox(height: 30),
            if (isUserHasSpot)
              Column(
                children: [
                  const SizedBox(height: 15),
                  itemProfile(
                      'Current Park Spot', currentparkspot, CupertinoIcons.car),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CupertinoAlertDialog(
                              title: const Text('Leave Car Spot'),
                              content: const Text(
                                  'Are you sure for leaving car parking spot?'),
                              actions: <Widget>[
                                CupertinoDialogAction(
                                  onPressed: () {
                                    doneLeavingCarSpot();
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const HomePage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Yes'),
                                ),
                                CupertinoDialogAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('No'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.lock_open,
                              size: 40, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Leave Car Spot',
                            style: GoogleFonts.openSans(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
              onPressed: () {},
              icon: const Icon(CupertinoIcons.person, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget itemProfile(String title, String subtitle, IconData iconData) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 5),
            color: Colors.purpleAccent.withOpacity(.2),
            spreadRadius: 2,
            blurRadius: 10,
          )
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.openSans(
            fontSize: 20,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.openSans(
            fontSize: 18,
          ),
        ),
        leading: Icon(iconData),
        trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
        tileColor: Colors.white,
      ),
    );
  }
}
