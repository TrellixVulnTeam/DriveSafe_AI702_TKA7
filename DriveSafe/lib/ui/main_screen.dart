import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:drivesafe/navigator.dart';
import 'package:drivesafe/utils/Fonts.dart';
import 'package:drivesafe/utils/SizeConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'home.dart';

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  MainScreen(this.cameras);
  @override
  _MainScreenState createState() => _MainScreenState();
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  CarouselController carouselController = CarouselController();

  Random random = Random();
  int selectedCar = 0;
  String carName = 'Hatchback';
  String contact = '';
  bool isEditMode = false;
  bool invalidPhone = false;
  TextEditingController textController = TextEditingController();
  bool useGPS, notify;

  @override
  void initState() {
    super.initState();

    useGPS = false;
    notify = true;

    WidgetsBinding.instance.addObserver(this);

    setOrientation();
  }

  setOrientation() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await setOrientation();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    Fonts().init(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          child: makeBody(context)),
    );
  }

  Widget makeBody(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RichText(
                  text: TextSpan(
                style: TextStyle(
                    fontFamily: Fonts.bold, fontSize: Fonts.customSize(8)),
                children: [
                  TextSpan(
                      text: 'Drive', style: TextStyle(color: Colors.black)),
                  TextSpan(text: 'Safe', style: TextStyle(color: Colors.green)),
                ],
              )),
            ),
            SizedBox(height: Fonts.customSize(7)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Vehicle',
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: Fonts.bold,
                      fontSize: Fonts.customSize(5),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, size: Fonts.customSize(7.5)),
                    onPressed: () {
                      settingsSheet(context);
                    },
                  ),
                ],
              ),
            ),
            showVehicleMenu(),
            SizedBox(height: Fonts.customSize(3)),
            Center(
              child: Container(
                width: SizeConfig.screenWidth * 0.85,
                child: FlatButton(
                  onPressed: () {
                    Navigator.of(context).push(FadeRouteBuilder(
                        page:
                            HomePage(widget.cameras, useGPS, contact, notify)));
                  },
                  padding: EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Driving',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Fonts.customSize(5.5),
                            fontFamily: Fonts.normal),
                      ),
                      SizedBox(width: Fonts.customSize(3)),
                      Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      )
                    ],
                  ),
                  color: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            SizedBox(height: Fonts.customSize(15)),
          ],
        ),
      ),
    );
  }

  showVehicleMenu() {
    return Container(
      padding: EdgeInsets.only(
          top: Fonts.customSize(6), bottom: Fonts.customSize(6)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarouselSlider(
            carouselController: carouselController,
            options: CarouselOptions(
              height: 400,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              enlargeCenterPage: true,
              onPageChanged: (i, reason) {
                setState(() {
                  selectedCar = i;
                });
                _updateCar();
              },
              scrollDirection: Axis.horizontal,
            ),
            items: [1, 2, 3].map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                      width: SizeConfig.screenWidth * 0.95,
                      margin:
                          EdgeInsets.symmetric(horizontal: 5.0, vertical: 18),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            new BoxShadow(
                                color: Colors.grey[200],
                                blurRadius: 15.0,
                                spreadRadius: 5.0,
                                offset: Offset(0.0, 0.0))
                          ],
                          borderRadius: BorderRadius.circular(10)),
                      child: getImage(i));
                },
              );
            }).toList(),
          ),
          SizedBox(height: Fonts.customSize(6)),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                  child: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        carouselController.previousPage(
                            curve: Curves.fastOutSlowIn);
                      })),
              Expanded(
                  child: Center(
                      child: Text(
                carName,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: Fonts.bold,
                    fontSize: Fonts.size45),
              ))),
              Flexible(
                  child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        carouselController.nextPage(
                            curve: Curves.fastOutSlowIn);
                      }))
            ],
          )
        ],
      ),
    );
  }

  settingsSheet(BuildContext context) {
    FocusNode focusNode = FocusNode();
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              child: Container(
                  padding: EdgeInsets.only(
                    right: Fonts.customSize(7),
                    left: Fonts.customSize(7),
                    top: Fonts.customSize(6),
                    bottom: Fonts.customSize(30),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Settings',
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: Fonts.bold,
                              fontSize: Fonts.customSize(8))),
                      SizedBox(height: Fonts.customSize(4)),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15)),
                        child: SwitchListTile(
                          value: useGPS,
                          onChanged: (value) {
                            setState(() {
                              useGPS = value;
                            });
                          },
                          title: Text(
                            'Enable GPS',
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: Fonts.bold,
                                fontSize: Fonts.size45),
                          ),
                          activeColor: Colors.green,
                        ),
                      ),
                      SizedBox(height: Fonts.customSize(3)),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(15)),
                        child: SwitchListTile(
                          value: notify,
                          onChanged: (value) {
                            setState(() {
                              notify = value;
                            });
                          },
                          title: Text(
                            'Smartwatch Notification',
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: Fonts.bold,
                                fontSize: Fonts.size45),
                          ),
                          activeColor: Colors.green,
                        ),
                      ),
                      SizedBox(height: Fonts.customSize(3)),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            title: Text(
                              'EMERGENCY CONTACT',
                              style: TextStyle(
                                  fontFamily: Fonts.bold,
                                  fontSize: Fonts.size3,
                                  color: Colors.grey),
                            ),
                            subtitle: isEditMode
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: TextFormField(
                                      focusNode: focusNode,
                                      keyboardType: TextInputType.phone,
                                      initialValue: contact,
                                      decoration: InputDecoration(
                                        errorText: invalidPhone
                                            ? 'Invalid Phone Number'
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          contact = value;
                                        });
                                      },
                                    ),
                                  )
                                : Text(
                                    contact.length != 10 ? 'Not Set' : contact,
                                    style: TextStyle(
                                        fontFamily: Fonts.bold,
                                        fontSize: Fonts.size5,
                                        color: Colors.black),
                                  ),
                            trailing: IconButton(
                                icon: Icon(
                                    isEditMode
                                        ? Icons.check_circle
                                        : Icons.edit,
                                    size: Fonts.customSize(7),
                                    color: isEditMode
                                        ? Colors.green
                                        : Colors.grey[600]),
                                onPressed: () {
                                  if (isEditMode && contact.length != 10) {
                                    setState(() {
                                      invalidPhone = true;
                                    });
                                  } else
                                    setState(() {
                                      invalidPhone = false;
                                      isEditMode = !isEditMode;
                                      focusNode.requestFocus();
                                    });
                                }),
                          ),
                        ),
                      ),
                    ],
                  )),
            );
          });
        });
  }

  getImage(int i) {
    switch (i) {
      case 1:
        return Image.asset('img/hatchback.png');
        break;
      case 2:
        return Image.asset('img/sedan.png');
        break;
      case 3:
        return Image.asset('img/suv.png');
        break;
      default:
    }
  }

  _updateCar() {
    switch (selectedCar) {
      case 0:
        setState(() {
          carName = 'Hatchback';
        });
        break;
      case 1:
        setState(() {
          carName = 'Sedan';
        });
        break;
      case 2:
        setState(() {
          carName = 'SUV';
        });
        break;
      default:
    }
  }
}
