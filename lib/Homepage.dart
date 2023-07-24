import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trackmate/feed.dart';
import 'package:trackmate/image_upload.dart';
import 'package:http/http.dart' as http;

class homePage extends StatefulWidget {
  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  Completer<GoogleMapController> _controller = Completer();
  double lat = 0;
  double long = 0;
  double shared_longitude = 0;
  double shared_latitude = 0;
  bool notification_taped = false;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  var _kGoogle = CameraPosition(
    target: LatLng(24.5672911, 73.7491331),
    zoom: 20,
  );

  final List<Marker> _markers = <Marker>[];
  // get user location and upload it on
  getUserCurrentLocation() async {
    print('clicked');
    bool serviceEnabled;
    LocationPermission permission;
    final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
    } else if (serviceEnabled) {
      final position = await _geolocatorPlatform.getCurrentPosition(
          locationSettings:
              LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      print(
          " 'longitude': ${position.longitude},'latitude': ${position.latitude},'altitude': ${position.altitude},");

      updateToDatabase();
      lat = position.latitude;
      long = position.longitude;

      if (!notification_taped) {
        _markers.add(
          Marker(
              markerId: MarkerId('1'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(
                title: 'My Position',
              )),
        );
      }

      return position;
    }
  }

  updateToDatabase() async {
    final ref = FirebaseDatabase.instance.ref('users');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final fcm_token = await messaging.getToken();
    print(lat);
    print(long);
    ref.child('${uid}').update(
        {"fcm_token": "$fcm_token", "latitude": lat, "longitude": long});
  }

  _sendNotification(fcm_token, uid_sender) async {
    Uri post_url = Uri.parse("https://fcm.googleapis.com/fcm/send");

    final payload = {
      "notification": {
        "body": "$uid's location ",
        "title": "Someone shared location",
        'bigText': "Latitude:${lat} || Longitude:${long}"
      },
      "priority": "high",
      'message': "werty",
      "data": {
        "path": 'homePage',
        "id": "$uid",
        "lat": "${lat}",
        "long": "${long}"
      },
      'to': "${fcm_token.toString()}",
    };
    final headers = {
      'content-type': 'application/json',
      'Authorization':
          'key=AAAArdgX0dE:APA91bHreF-YX3WhdU84EiPBu0mzRWGcAdE03QZUNSvRR8bnau2KciSOlKjaH4R42-D2v4_kjfOgKdLCl737EypIi0Pmljd237l1nsZ1hz2ciUiYA-3HuNxUtT2PMyGivfXOJFJMetw1' // 'key=YOUR_SERVER_KEY'
    };

    final response = await http.post(post_url,
        body: json.encode(payload),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      print(' CFM error');
      return false;
    }
  }

  int _currentIndex = 0;
  @override
  void initState() {
    getUserCurrentLocation();

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref();

    Route _createRoute(Widget child) {
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(-1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
    }

    Widget map() {
      return Container(
        // in the below line, creating google maps.
        child: GoogleMap(
          rotateGesturesEnabled: true,
          myLocationButtonEnabled: true,

          // in the below line, setting camera position
          initialCameraPosition: _kGoogle,
          // in the below line, specifying map type.
          mapType: MapType.normal,
          // in the below line, setting user location enabled.
          myLocationEnabled: true,

          markers: _markers.toSet(),
          // in the below line, setting compass enabled.
          compassEnabled: true,
          // in the below line, specifying controller on map complete.
          onMapCreated: (GoogleMapController controller) {
            _controller.isCompleted ? null : _controller.complete(controller);
          },
        ),
      );
    }

    Widget users_list(_users, users) {
      return Container(
        child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              content: SingleChildScrollView(
                            child: Text(
                              "User's other details will be shown here.",
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ));
                        });
                  },
                  child: ListTile(
                    title: Text(_users[index]),
                    trailing: GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                    actions: [
                                      MaterialButton(
                                        onPressed: () {
                                          _sendNotification(
                                              "${users[_users[index]]['fcm_token']}",
                                              "${users[index]}");
                                        },
                                        child: Text('yes'),
                                      )
                                    ],
                                    content: SingleChildScrollView(
                                      child: Text(
                                        "Do you want to share location with selected user",
                                        style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ));
                              });
                        },
                        child: Icon(Icons.share)),
                    subtitle: Text(
                        "Longitude: ${users[_users[index]]['longitude']}|| Latitude: ${users[_users[index]]['latitude']}"),
                  ),
                ),
              );
            }),
      );
    }

    // print(_markers);
    return StreamBuilder(
      stream: ref.onValue,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> event) {
        dynamic data = event.data?.snapshot.value;
        List _users = [];
        Map users = {};
        FirebaseMessaging.onMessageOpenedApp
            .listen((RemoteMessage message) async {
          print('.....................................');
          print(message.data);
          print(message.contentAvailable);
          print(await message.notification);
          print('.....................................');
          if ('${await message.data['path']}' == 'homePage')
            setState(() {
              notification_taped = true;
              shared_latitude = double.parse(message.data['lat'].toString());
              shared_longitude = double.parse(message.data['long'].toString());
              _kGoogle = CameraPosition(
                target: LatLng(double.parse(message.data['lat'].toString()),
                    double.parse(message.data['long'].toString())),
                zoom: 14,
              );
            });
          _markers.clear();
          _markers.add(
            Marker(
                markerId: MarkerId('1'),
                position: LatLng(shared_latitude, shared_longitude),
                infoWindow: InfoWindow(
                  title: "${message.data['id'].toString()}",
                )),
          );
        });
        if (data != null && data['users'] != null) {
          users = data['users'];
          users.forEach((_uid, detail) {
            if (detail['latitude'] != null &&
                detail['longitude'] != null &&
                _uid != uid) {
              if (!_users.contains(_uid)) {
                _users.add(_uid);
              }
              if (!notification_taped) {
                _markers.add(
                  Marker(
                      markerId: MarkerId('$uid'),
                      position: LatLng(detail['latitude'], detail['longitude']),
                      infoWindow: InfoWindow(
                          title: '${detail['name']}',
                          snippet:
                              '${detail['latitude']}|| ${detail['longitude']}')),
                );
              }
            }
          });
        }
        final List<Widget> _pages = [
          map(),
          users_list(_users, users),
          DisplayImagesPage(),
          ImageUploadPage(
            lat: lat,
            long: long,
          )
        ];

        return Scaffold(
          appBar: AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.popAndPushNamed(context, '/');
                  },
                  child: Icon(
                    Icons.logout,
                    color: Colors.black,
                  ),
                ),
              )
            ],
            title: Text(
              "Track Mate",
              style: GoogleFonts.inter(color: Colors.black),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: Color.fromARGB(220, 89, 139, 237),
            unselectedItemColor: Color.fromARGB(208, 109, 116, 122),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(208, 109, 116, 122),
            ),
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(220, 89, 139, 237)),
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                  child: Icon(Icons.map),
                ),
                label: 'Map view',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                    child: Icon(Icons.list)),
                label: 'List View',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                    child: Icon(Icons.post_add)),
                label: 'Post',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                    child: Icon(Icons.feed)),
                label: 'Feed',
              ),
            ],
          ),
          body: _pages[_currentIndex],
        );
      },
    );
  }
}
