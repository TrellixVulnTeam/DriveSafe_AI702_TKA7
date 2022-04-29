import 'dart:async';

import 'package:drivesafe/navigator.dart';
import 'package:drivesafe/ui/main_screen.dart';
import 'package:drivesafe/utils/Fonts.dart';
import 'package:drivesafe/utils/SizeConfig.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

List<CameraDescription> cameras;
Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveSafe Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
        Duration(seconds: 2),
        () => Navigator.pushReplacement(
            context, FadeRouteBuilder(page: MainScreen(cameras))));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    Fonts().init(context);

    return Scaffold(
      body: Container(
        child: Center(
          child: RichText(
              text: TextSpan(
            style: TextStyle(
                fontFamily: Fonts.bold, fontSize: Fonts.customSize(14)),
            children: [
              TextSpan(text: 'Drive', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'Safe', style: TextStyle(color: Colors.green)),
            ],
          )),
        ),
      ),
    );
  }
}
