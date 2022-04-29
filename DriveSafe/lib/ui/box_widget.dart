import 'package:drivesafe/tflite/recognition.dart';
import 'package:flutter/material.dart';

/// Individual bounding box
class BoxWidget extends StatelessWidget {
  final Recognition result;
  final Rect location;

  const BoxWidget({
    Key key,
    this.result,
    this.location,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    Color color = Colors.primaries[
        (result.label.length + result.label.codeUnitAt(0) + result.id) %
            Colors.primaries.length];
    // WidgetsBinding.instance.addPostFrameCallback(
    //     (_) => onAfterBuild(context, area, location, safeDistance));
    return Positioned(
      left: location.left,
      top: location.top,
      width: location.width,
      height: location.height,
      child: Container(
        width: location.width,
        height: location.height,
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.all(Radius.circular(2))),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: color,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(result.label),
                  Text(" " + result.score.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void onAfterBuild(
  //     BuildContext context, double area, Rect location, Rect safeDistanceFOV) {
  //   // I can now safely get the dimensions based on the context
  //   if (area >= 80.0 &&
  //       location.height >= (safeDistanceFOV.height * 0.5) &&
  //       location.width >= (safeDistanceFOV.width * 0.5)) {
  //     alertCallback(1);
  //   }
  // }
}
