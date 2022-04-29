import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audio_cache.dart';
import 'package:bordered_text/bordered_text.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:drivesafe/tflite/recognition.dart';
import 'package:drivesafe/tflite/stats.dart';
import 'package:drivesafe/ui/box_widget.dart';
import 'package:drivesafe/ui/box_widgetFOV.dart';
import 'package:drivesafe/utils/Fonts.dart';
import 'package:drivesafe/utils/SizeConfig.dart';
import 'package:drivesafe/utils/FOV.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
import 'package:flashlight/flashlight.dart';
import 'package:sensors/sensors.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camera_view.dart';
import 'package:rxdart/subjects.dart';

/// [HomePage] stacks [CameraView] and [BoxWidget]s with bottom sheet for stats
class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool useGPS, notify;
  final String emergencyContact;

  HomePage(this.cameras, this.useGPS, this.emergencyContact, this.notify);
  @override
  _HomePageState createState() =>
      _HomePageState(useGPS, emergencyContact, notify);
}

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool useGPS, notify;
  String emergencyContact;

  _HomePageState(this.useGPS, this.emergencyContact, this.notify);

  /// Results to draw bounding boxes
  List<Recognition> results;

  Stats stats;
  int alertInt = 0;
  Random random = Random();
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  bool _visible = true;
  bool isIOS = false;
  bool alertVisible = false;

  double velocity = 0;
  double highestVelocity = 0.0;
  double currentSpeed = 0;
  double gpsSpeed = 0;

  //Screen Resolution Varaibles
  double screenWidth, screenHeight, growthRightFOV, growthLeftFOV;
  double valOffset, topOffset, leftOffset;
  Rect safeDistanceFOV, personRightFOV, personLeftFOV;
  int frameCounterLeft = 0;
  int frameCounterRight = 0;

  List<Rect> personRightGrowth = [];
  List<Rect> personLeftGrowth = [];

  StreamSubscription<UserAccelerometerEvent> speedListener;
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  List<String> gifs = [
    'img/warning.gif',
    'img/running.gif',
    'img/boy.gif',
    'img/stop.gif',
    'img/traffic.gif'
  ];
  List<String> cautionTexts = [
    'Please maintain safe distance and reduce speed',
    'Person Detected\nPlease slow down to avoid collision',
    'Person running towards you. Watchout !!',
    'Stop-Sign Ahead\nSlow Down ! Proceed with caution',
    'Traffic Junction Ahead\nSlow Down ! Proceed with caution',
  ];
  List<dynamic> alertColors = [
    Colors.red,
    Colors.orange,
    Colors.blue,
    Colors.white,
    Color.fromRGBO(36, 36, 36, 1)
  ];

  @override
  void initState() {
    super.initState();
    isIOS = Platform.isIOS ? true : false;
    _requestPermissions();
    initNotification();

    dev.log("useGPS = $useGPS");

    Future.delayed(const Duration(seconds: 4), () {
      if (this.mounted) {
        setState(() {
          _visible = false;
        });
      }
    });

    setOrientation();

    speedListener =
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      _onAccelerate(event);
    });

    if (useGPS) initLocation();
  }

  initLocation() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen((position) {
      setState(() {
        gpsSpeed = position == null ? 0 : ((position.speed * 18) / 5);
        if (gpsSpeed < 0) {
          gpsSpeed = 0;
        }
      });

      dev.log("GPS Speed = $gpsSpeed");
    });
  }

  void _onAccelerate(UserAccelerometerEvent event) {
    double acceleration =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    double gForce = acceleration / 9.8;

    if (gForce > 3.5) {
      dev.log('Acceleration = $acceleration');
      dev.log('G-Force = $gForce');

      setState(() {
        alertInt = 6;
      });
    }
  }

  initNotification() async {
    IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            onDidReceiveLocalNotification:
                (int id, String title, String body, String payload) async {
              didReceiveLocalNotificationSubject.add(ReceivedNotification(
                  id: id, title: title, body: body, payload: payload));
            });
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
      if (payload != null) {
        debugPrint('notification payload: $payload');
      }
    });
  }

  setOrientation() {
    SystemChrome.setPreferredOrientations([
      isIOS ? DeviceOrientation.landscapeRight : DeviceOrientation.landscapeLeft
    ]);
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _initFOV() {
    screenWidth = SizeConfig.screenWidth;
    screenHeight = SizeConfig.screenHeight;
    valOffset = (isIOS ? 0.52 : 0.45) / screenHeight;
    leftOffset = isIOS ? 1 : 0.6;
    topOffset = valOffset * screenHeight;
    safeDistanceFOV = Rect.fromLTWH(
        screenWidth * 0.17, 0.0, screenWidth * 0.65, screenHeight);
    //TODO : Person FOV Not needed
    personRightFOV = Rect.fromLTWH(screenWidth * 0.5, screenHeight * 0.2,
        screenWidth * 0.5, screenHeight * 0.8);
    personLeftFOV = Rect.fromLTWH(
        0, screenHeight * 0.2, screenWidth * 0.5, screenHeight * 0.8);
    growthRightFOV = safeDistanceFOV.topRight.dx + screenWidth * 0.1;
    growthLeftFOV = safeDistanceFOV.topLeft.dx - screenWidth * 0.1;
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    speedListener.cancel();
  }

  @override
  Widget build(BuildContext context) {
    setOrientation();

    SizeConfig().init(context);
    Fonts().init(context);
    _initFOV();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // Camera View
          CameraView(resultsCallback, statsCallback, widget.cameras),

          Visibility(
            visible: _visible,
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Transform.rotate(
                  angle: -pi / 2,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 150,
                            child: Image.asset(
                              'img/rotate.gif',
                            )),
                        Text(
                          'Rotate Screen',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: Fonts.size3,
                              fontFamily: Fonts.normal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bounding boxes
          boundingBoxes(results),
          // boundingBoxesFOV(),

          //Speedometer
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Opacity(
                opacity: 0.5,
                child: GestureDetector(
                  onTap: () {
                    if (!useGPS) {
                      setState(() {
                        currentSpeed = (currentSpeed + 10) % 70;
                      });
                      dev.log('speed -> $currentSpeed');
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          useGPS
                              ? gpsSpeed.toStringAsFixed(0)
                              : currentSpeed.toStringAsFixed(0),
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: Fonts.bold,
                              fontSize: Fonts.size35),
                        ),
                        Text(
                          'km/h',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: Fonts.normal,
                              fontSize: Fonts.customSize(2)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          //Inference Time
          stats != null
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Opacity(
                      opacity: 0.5,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${stats.inferenceTime}',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: Fonts.normal,
                              fontSize: Fonts.customSize(2)),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
          // AlertView
          alertInt >= 1
              ? alertInt == 6
                  ? showSOSView()
                  : showAlertView(alertInt)
              : Container(
                  width: 0,
                  height: 0,
                ),
        ],
      ),
    );
  }

  Widget showAlertView(int _alertInt) {
    if (!alertVisible) {
      playAudio(false);
      toggleFlashLight();
      if (notify) _showNotification();
    }
    dev.log('Alert Int ==>' + _alertInt.toString());
    setState(() {
      alertVisible = true;
    });
    return Container(
      width: SizeConfig.screenWidth,
      height: SizeConfig.screenHeight,
      color: alertColors[_alertInt - 1],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Center(
              child: Container(
                height: screenHeight * .75,
                child: Image.asset(
                  gifs[_alertInt - 1],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BorderedText(
                  strokeWidth: 6,
                  strokeColor: Colors.black,
                  child: Text(
                    'Caution',
                    style: TextStyle(
                        color: Colors.yellow,
                        fontSize: Fonts.customSize(10.5),
                        fontFamily: Fonts.bold),
                  ),
                ),
                SizedBox(height: Fonts.customSize(4.5)),
                Text(
                  cautionTexts[_alertInt - 1],
                  style: TextStyle(
                      color: _alertInt == 4 ? Colors.black : Colors.white,
                      fontFamily: Fonts.normal,
                      fontSize: Fonts.size3),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  toggleFlashLight() async {
    CameraController controller =
        CameraController(widget.cameras.first, ResolutionPreset.ultraHigh);
    int count = 0;
    Timer.periodic(Duration(milliseconds: 800), (t) {
      isIOS ? Flashlight.lightOn() : controller.setFlashMode(FlashMode.torch);

      count++;
      Future.delayed(Duration(milliseconds: 400), () {
        isIOS ? Flashlight.lightOff() : controller.setFlashMode(FlashMode.off);
      });

      if (count == 3) t.cancel();
    });
  }

  Widget showSOSView() {
    if (!alertVisible) {
      playAudio(true);
      toggleFlashLight();
      _showNotification();
    }

    setState(() {
      alertVisible = true;
    });

    return Container(
      width: SizeConfig.screenWidth,
      height: SizeConfig.screenHeight,
      color: Colors.blueAccent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularCountDownTimer(
              duration: 60,
              initialDuration: 0,
              controller: CountDownController(),
              width: Fonts.customSize(10),
              height: Fonts.customSize(10),
              ringColor: Colors.blueAccent[100],
              fillColor: Colors.white,
              backgroundColor: Colors.blue[800],
              backgroundGradient: null,
              strokeWidth: 20.0,
              strokeCap: StrokeCap.round,
              textStyle: TextStyle(
                  fontSize: 33.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              textFormat: CountdownTextFormat.S,
              isReverse: true,
              isReverseAnimation: true,
              isTimerTextShown: true,
              autoStart: true,
              onStart: () {
                print('Countdown Started');
              },
              onComplete: () {
                setState(() {
                  alertInt = 0;
                  alertVisible = false;
                });
                sendSMS();
                print('Countdown Ended');
              },
            ),
            SizedBox(height: Fonts.customSize(2)),
            Text(
              'Are you Safe?',
              style: TextStyle(
                  fontFamily: Fonts.bold,
                  fontSize: Fonts.customSize(6),
                  color: Colors.white),
            ),
            SizedBox(height: Fonts.customSize(2)),
            Text(
              'If you require emergency assistance please click on the CALL EMERGENCY button. If not required please cancel this message.',
              style: TextStyle(
                  fontFamily: Fonts.normal,
                  fontSize: Fonts.customSize(2.5),
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Fonts.customSize(5)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Fonts.customSize(5)),
              child: Row(
                children: [
                  Expanded(
                      child: FlatButton.icon(
                    onPressed: () {
                      sendSMS();
                    },
                    icon: Icon(
                      Icons.call,
                      color: Colors.white,
                    ),
                    label: Text(
                      'CALL EMERGENCY ',
                      style: TextStyle(
                          letterSpacing: 1,
                          fontFamily: Fonts.bold,
                          color: Colors.white,
                          fontSize: Fonts.customSize(2.5)),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    color: Colors.redAccent,
                    padding: EdgeInsets.all(15),
                  )),
                  SizedBox(width: Fonts.customSize(8)),
                  Expanded(
                      child: FlatButton.icon(
                    onPressed: () {
                      setState(() {
                        alertInt = 0;
                        alertVisible = false;
                      });
                    },
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.blueAccent,
                    ),
                    label: Text(
                      'CANCEL',
                      style: TextStyle(
                          letterSpacing: 1,
                          fontFamily: Fonts.bold,
                          color: Colors.blueAccent,
                          fontSize: Fonts.customSize(2.5)),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.white)),
                    color: Colors.white,
                    padding: EdgeInsets.all(15),
                  )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  sendSMS() async {
    if (Platform.isAndroid) {
      LocationData location = await Location().getLocation();
      String message =
          'I require immediate emergency assistance.\n\nMy Current Location is : https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
      Telephony.instance.sendSms(
          to: "+91$emergencyContact",
          message: message,
          statusListener: (status) {
            if (status == SendStatus.SENT) {
              setState(() {
                alertInt = 0;
                alertVisible = false;
              });
              Navigator.of(context).pop();
            }
          });
    } else if (Platform.isIOS) {
      //var uri = 'sms:0091$emergencyContact&body=$message';
      var uri = 'shortcuts://run-shortcut?name=DriveSafeSOS';
      await launch(uri);
      setState(() {
        alertInt = 0;
        alertVisible = false;
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> _showNotification() async {
    int randomNumber = random.nextInt(100);
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        randomNumber,
        'Caution',
        'Please maintain safe distance and drive safely',
        platformChannelSpecifics,
        payload: 'item x');
  }

  playAudio(bool isSOS) async {
    final player = AudioCache();
    await player.play('warning.mp3');

    if (!isSOS)
      Future.delayed(Duration(seconds: 3)).then((value) {
        setState(() {
          alertInt = 0;
          alertVisible = false;
          // Flashlight.lightOff();
        });
      });
  }

  resultsAlert(List<Recognition> results) {
    Rect resultLocation, interSafeDistance;
    double area;
    results.forEach((res) {
      resultLocation = Rect.fromLTWH(
          res.renderLocation.left * leftOffset,
          res.renderLocation.top * topOffset,
          res.renderLocation.width,
          res.renderLocation.height);
      //Intersection Over Union
      interSafeDistance = resultLocation.intersect(safeDistanceFOV);
      area = ((interSafeDistance.height * interSafeDistance.width) /
              (resultLocation.height * resultLocation.width)) *
          100;
      //dev.log('topleft ==>' + safeDistanceFOV.topRight.toString());

      if (this.mounted) {
        // Alert 1 = Not Maintaining Safe Distance
        if ((currentSpeed >= 40 || gpsSpeed >= 40) &&
            area >= 80.0 &&
            resultLocation.height >= (safeDistanceFOV.height * 0.4) &&
            resultLocation.width >= (safeDistanceFOV.width * 0.4)) {
          setState(() {
            this.alertInt = 1;
          });
        }
        //Alert 2 = Person watch out
        if (res.label == 'person' &&
            (currentSpeed >= 10 || gpsSpeed >= 10) &&
            area >= 60 &&
            resultLocation.height >= (safeDistanceFOV.height * 0.4)) {
          setState(() {
            this.alertInt = 2;
          });
        }
        //Alert 3 = Person Growth Algorithm
        else if (res.label == 'person') {
          //Case 1 : Person Right FOV
          if (resultLocation.topLeft.dx > screenWidth * 0.5) {
            double growthRight;
            if (personRightGrowth.length == 0 &&
                (resultLocation.topLeft.dx > growthRightFOV)) {
              setState(() {
                personRightGrowth.add(resultLocation);
              });
            } else if (personRightGrowth.length == 1 &&
                (resultLocation.topLeft.dx < growthRightFOV)) {
              setState(() {
                personRightGrowth.add(resultLocation);
              });
              growthRight =
                  (resultLocation.height / personRightGrowth.first.height) *
                      100;
              dev.log('Growth Right ==> ' + growthRight.toString());
              if (growthRight >= 80) {
                setState(() {
                  this.alertInt = 3;
                  personRightGrowth = [];
                });
              } else {
                setState(() {
                  personRightGrowth = [];
                });
              }
            } else if (personRightGrowth.length == 1) {
              setState(() {
                frameCounterRight += 1;
              });
              if (frameCounterRight == 5) {
                setState(() {
                  personRightGrowth = [];
                  frameCounterRight = 0;
                });
              }
            }
            dev.log('Right Array ==> ' + personRightGrowth.toString());
          }
          //Case 2 : Person Left FOV
          else if (resultLocation.topRight.dx < screenWidth * 0.5) {
            double growthLeft;
            if (personLeftGrowth.length == 0 &&
                (resultLocation.topRight.dx < growthLeftFOV)) {
              setState(() {
                personLeftGrowth.add(resultLocation);
              });
            } else if (personLeftGrowth.length == 1 &&
                (resultLocation.topRight.dx > growthLeftFOV)) {
              setState(() {
                personLeftGrowth.add(resultLocation);
              });
              growthLeft =
                  (resultLocation.height / personLeftGrowth.first.height) * 100;
              dev.log('Growth Left ==> ' + growthLeft.toString());
              if (growthLeft >= 80) {
                setState(() {
                  this.alertInt = 3;
                  personLeftGrowth = [];
                });
              } else {
                setState(() {
                  personLeftGrowth = [];
                });
              }
            } else if (personLeftGrowth.length == 1) {
              setState(() {
                frameCounterLeft += 1;
              });
              if (frameCounterLeft == 5) {
                setState(() {
                  personLeftGrowth = [];
                  frameCounterLeft = 0;
                });
              }
            }
            dev.log('Left Array ==> ' + personLeftGrowth.toString());
          }
        }
        //Alert 4 = Stop Sign Ahead
        else if (res.label == 'stop sign' &&
            (currentSpeed >= 20 || gpsSpeed >= 20)) {
          setState(() {
            this.alertInt = 4;
          });
        }
        //Alert 5 = Traffic Light Junction Ahead
        // else if (res.label == 'traffic light' &&
        //     (currentSpeed >= 20 || gpsSpeed >= 20)) {
        //   setState(() {
        //     this.alertInt = 5;
        //   });
        // }
      }
    });
  }

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    resultsAlert(results);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        children: results
            .map((e) => BoxWidget(
                  result: e,
                  location: Rect.fromLTWH(
                      e.renderLocation.left * leftOffset,
                      e.renderLocation.top * topOffset,
                      e.renderLocation.width,
                      e.renderLocation.height),
                ))
            .toList(),
      ),
    );
  }

  Widget boundingBoxesFOV() {
    Rect personWideFOV = Rect.fromLTWH(0, SizeConfig.screenHeight * 0.2,
        SizeConfig.screenWidth, SizeConfig.screenHeight * 0.8);
    Rect safeDistanceFOV = Rect.fromLTWH(
        SizeConfig.screenWidth * 0.17,
        0.0,
        SizeConfig.screenWidth * 0.65 + SizeConfig.screenHeight * 0.1,
        SizeConfig.screenHeight);
    Rect personRightFOV = Rect.fromLTWH(
        SizeConfig.screenWidth * 0.5,
        SizeConfig.screenHeight * 0.2,
        SizeConfig.screenWidth * 0.5,
        SizeConfig.screenHeight * 0.8);
    Rect personLeftFOV = Rect.fromLTWH(0, SizeConfig.screenHeight * 0.2,
        SizeConfig.screenWidth * 0.5, SizeConfig.screenHeight * 0.8);
    Rect personMidFOV = Rect.fromLTWH(
        SizeConfig.screenWidth * 0.17,
        SizeConfig.screenHeight * 0,
        SizeConfig.screenWidth * 0.65,
        SizeConfig.screenHeight * 1);
    return BoxWidgetFOV(
      isIOS: isIOS,
      fov: FOV('SafeDistance', safeDistanceFOV),
    );
  }

  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results) {
    if (this.mounted) {
      setState(() {
        this.results = results;
      });
    }
  }

  void alertCallback(int alertIntV) {
    if (this.mounted) {
      if (alertIntV == 1 && currentSpeed >= 40) {
        setState(() {
          this.alertInt = alertIntV;
          //dev.log("Safe ===>" + safeAlertv.toString());
        });
      }
    }
  }

  /// Callback to get inference stats from [CameraView]
  void statsCallback(Stats stats) {
    if (this.mounted) {
      setState(() {
        this.stats = stats;
      });
    }
  }

  static const BOTTOM_SHEET_RADIUS = Radius.circular(24.0);
  static const BORDER_RADIUS_BOTTOM_SHEET = BorderRadius.only(
      topLeft: BOTTOM_SHEET_RADIUS, topRight: BOTTOM_SHEET_RADIUS);
}

/// Row for one Stats field
class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  StatsRow(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(fontSize: 16),
          ),
          Text(
            right,
            style: TextStyle(fontSize: 16),
          )
        ],
      ),
    );
  }
}
