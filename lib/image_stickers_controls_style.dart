import 'package:flutter/material.dart';

/// Used to set style for sticker controls thumb.
class ImageStickersControlsStyle {
  /// Controls size
  double size;

  /// Background color for controls thumb.
  /// Set [color] to [Colors.transparent] if you don't need a background color.
  Color color;

  ///Set child to use any custom widget as controls. E.g Icon
  Widget? child;

  /// Controls border radius.
  /// Default is [size] / 2
  /// Set to [BorderRadius.zero] for square controls
  BorderRadius? borderRadius;

  ImageStickersControlsStyle(
      {this.size = 30,
      this.color = Colors.blue,
      this.borderRadius,
      this.child});
}
