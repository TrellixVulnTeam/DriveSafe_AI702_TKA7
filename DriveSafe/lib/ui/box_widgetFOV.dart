import 'package:flutter/material.dart';
import 'package:drivesafe/utils/FOV.dart';

/// Individual bounding box
class BoxWidgetFOV extends StatelessWidget {
  final bool isIOS;
  final FOV fov;
  const BoxWidgetFOV({Key key, this.isIOS, this.fov}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Color for bounding box
    Color color = Colors.red;
    if (isIOS) {
      return Positioned(
        left: fov.location.left,
        top: fov.location.top,
        width: fov.location.width,
        height: fov.location.height,
        child: Container(
          width: fov.location.width,
          height: fov.location.height,
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
                    Text(fov.label),
                    //Text(" " + result.score.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Positioned(
        left: fov.location.left,
        top: fov.location.top,
        width: fov.location.width,
        height: fov.location.height,
        child: Container(
          width: fov.location.width,
          height: fov.location.height,
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
                    Text(fov.label),
                    //Text(" " + result.score.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
