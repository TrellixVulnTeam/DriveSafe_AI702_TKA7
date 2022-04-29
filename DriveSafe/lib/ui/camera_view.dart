import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:drivesafe/tflite/classifier.dart';
import 'package:drivesafe/tflite/recognition.dart';
import 'package:drivesafe/tflite/stats.dart';
import 'package:drivesafe/ui/camera_view_singleton.dart';
import 'package:drivesafe/utils/isolate_utils.dart';
import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// [CameraView] sends each frame for inference
class CameraView extends StatefulWidget {
  /// Callback to pass results after inference to [HomeView]
  final Function(List<Recognition> recognitions) resultsCallback;

  /// Callback to inference stats to [HomeView]
  final Function(Stats stats) statsCallback;
  final List<CameraDescription> cameras;

  /// Constructor
  const CameraView(this.resultsCallback, this.statsCallback, this.cameras);
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  /// List of available cameras
  List<CameraDescription> cameras;

  /// Controller
  CameraController cameraController;

  /// true when inference is ongoing
  bool predicting;

  /// Instance of [Classifier]
  Classifier classifier;

  /// Instance of [IsolateUtils]
  IsolateUtils isolateUtils;

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addObserver(this);

    // Camera initialization
    initializeCamera();

    // Create an instance of classifier to load model and labels
    classifier = Classifier();

    // Initially predicting = false
    predicting = false;

    // Spawn a new isolate
    isolateUtils = IsolateUtils();
    isolateUtils.start();
  }

  /// Initializes the camera by setting [cameraController]
  void initializeCamera() async {
    cameras = widget.cameras;
    // cameras[0] for rear-camera
    cameraController = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);

    cameraController.initialize().then((_) async {
      // Stream of image passed to [onLatestImageAvailable] callback
      await cameraController.startImageStream(onLatestImageAvailable);

      /// previewSize is size of each image frame captured by controller
      ///
      /// 352x288 on iOS, 240p (320x240) on Android with ResolutionPreset.low
      Size previewSize = cameraController.value.previewSize;

      /// previewSize is size of raw input image to the model
      CameraViewSingleton.inputImageSize = previewSize;

      // the display width of image on screen is
      // same as screenWidth while maintaining the aspectRatio
      Size screenSize = MediaQuery.of(context).size;
      CameraViewSingleton.screenSize = screenSize;

      if (Platform.isAndroid) {
        // On Android Platform image is initially rotated by 90 degrees
        // due to the Flutter Camera plugin
        CameraViewSingleton.ratio = screenSize.width / previewSize.height;
      } else {
        // For iOS
        CameraViewSingleton.ratio = screenSize.width / previewSize.width;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while the camera is not initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container();
    }

    return NativeDeviceOrientationReader(
        builder: (context) {
          final orientation =
              NativeDeviceOrientationReader.orientation(context);
          print('Received new orientation: $orientation');

          int turns;
          switch (orientation) {
            case NativeDeviceOrientation.landscapeLeft:
              turns = -1;
              break;
            case NativeDeviceOrientation.landscapeRight:
              turns = 1;
              break;
            case NativeDeviceOrientation.portraitDown:
              turns = 2;
              break;
            default:
              turns = 0;
              break;
          }

          double aspectRatio = cameraController.value.previewSize.height /
              cameraController.value.previewSize.width;

          return Transform.scale(
            scale: 1.2 / aspectRatio,
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Center(
                child: CameraPreview(cameraController),
              ),
            ),
          );
        },
        useSensor: false);
  }

  /// Callback to receive each frame [CameraImage] perform inference on it
  onLatestImageAvailable(CameraImage cameraImage) async {
    if ((this.mounted) &&
        classifier.interpreter != null &&
        classifier.labels != null &&
        (isolateUtils.sendPort != null)) {
      // If previous inference has not completed then return
      if (predicting) {
        return;
      }
      if (this.mounted) {
        setState(() {
          predicting = true;
        });
      }

      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

      // Data to be passed to inference isolate
      var isolateData = IsolateData(
          cameraImage, classifier.interpreter.address, classifier.labels);

      // We could have simply used the compute method as well however
      // it would be as in-efficient as we need to continuously passing data
      // to another isolate.

      /// perform inference in separate isolate
      Map<String, dynamic> inferenceResults = await inference(isolateData);

      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      // pass results to HomeView
      widget.resultsCallback(inferenceResults["recognitions"]);

      // pass stats to HomeView
      widget.statsCallback((inferenceResults["stats"] as Stats)
        ..totalElapsedTime = uiThreadInferenceElapsedTime);

      // set predicting to false to allow new frames
      if (this.mounted) {
        setState(() {
          predicting = false;
        });
      }
    }
  }

  /// Runs inference in another isolate
  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   if (this.mounted) {
  //     switch (state) {
  //       case AppLifecycleState.paused:
  //         cameraController.stopImageStream();
  //         break;
  //       case AppLifecycleState.resumed:
  //         await cameraController.startImageStream(onLatestImageAvailable);
  //         break;
  //       default:
  //     }
  //   }
  // }

  @override
  void dispose() {
    //WidgetsBinding.instance.removeObserver(this);
    isolateUtils.kill();
    cameraController.dispose();
    super.dispose();
  }
}
