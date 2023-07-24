import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trackmate/Homepage.dart';
import 'package:trackmate/firebase_options.dart';
import 'package:trackmate/login_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {}
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool notification_taped = false;
  String lat = '';
  String long = '';
  @override
  void initState() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission to receive notifications
    messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'location', 'Notification',
          description: 'Notification',
          importance: Importance.high,
          playSound: true,
          showBadge: true);
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      await flutterLocalNotificationsPlugin.show(
          0,
          "${message.notification?.title}",
          "${message.notification?.body}",
          NotificationDetails(
              android: AndroidNotificationDetails(
            'channel_id',
            'Notification',
            channelDescription: 'Notification',
          )));
      // print('.....................................');
      if (kDebugMode) {}
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (_) {
          return FirebaseAuth.instance.currentUser != null
              ? homePage()
              : LoginPage();
        }
      },
    );
  }
}
