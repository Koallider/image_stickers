import 'package:flutter/material.dart';

class ImageStickersControlsStyle {
  double size;
  Color color;
  Widget? child;
  BorderRadius? borderRadius;

  ImageStickersControlsStyle(
      {this.size = 30,
      this.color = Colors.blue,
      this.borderRadius,
      this.child});
}
