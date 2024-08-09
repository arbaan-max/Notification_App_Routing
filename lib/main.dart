import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:notification_routing/firebase_options.dart';
import 'package:notification_routing/views/home.dart';
import 'package:notification_routing/views/pages.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling background message: ${message.notification?.title ?? ''}');
  showOverlay();
}

Future<void> main() async {
  // Ensure that the Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (!await FlutterOverlayWindow.isPermissionGranted()) {
    FlutterOverlayWindow.requestPermission();
  }
  // Listen to overlay events
  FlutterOverlayWindow.overlayListener.listen((event) async {
    log("Overlay Event Received: $event");
    if (event == "openApp") {
      await openApp();
    }
  });

  runApp(const MyApp());
}

Future<void> openApp() async {
  const platform = MethodChannel('flutter_overlay_window/openApp');

  try {
    await platform.invokeMethod('openApp');
  } on PlatformException catch (e) {
    log("Failed to open app: '${e.message}'.");
  }
}

// overlay entry point
@pragma("vm:entry-point")
Future<void> overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: OverlayData(),
      ),
    ),
  );
}

class OverlayData extends StatefulWidget {
  const OverlayData({super.key});

  @override
  State<OverlayData> createState() => _OverlayDataState();
}

class _OverlayDataState extends State<OverlayData> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () async {
          await FlutterOverlayWindow.shareData("openApp");
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await FlutterOverlayWindow.closeOverlay();
                },
                icon: const Icon(Icons.close),
              ),
              const Text(
                "title",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

void showOverlay() async {
  FlutterOverlayWindow.showOverlay(
    alignment: OverlayAlignment.center,
    enableDrag: false,
    // width: 100,
    height: 400,
  );
}
