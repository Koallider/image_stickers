library image_stickers;

import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_stickers/image_stickers_controls_style.dart';

/// Class to describe a sticker
///
/// Set [editable] to true if you want to edit this sticker.
/// [x], [y], [size], [angle] will be updated after edit is finished.
class UISticker {
  ImageProvider imageProvider;
  double x;
  double y;
  double size;
  double angle;
  BlendMode blendMode;

  bool editable = false;

  UISticker(
      {required this.imageProvider,
      required this.x,
      required this.y,
      this.size = 100,
      this.angle = 0.0,
      this.blendMode = BlendMode.srcATop,
      this.editable = false});
}

/// A widget to draw [backgroundImage] and list of [UISticker]
///
/// Takes [ImageProvider] as a background image.
class ImageStickers extends StatefulWidget {
  final ImageProvider backgroundImage;
  final List<UISticker> stickerList;

  final double minStickerSize;
  final double maxStickerSize;

  final ImageStickersControlsStyle? stickerControlsStyle;

  const ImageStickers(
      {required this.backgroundImage,
      required this.stickerList,
      this.minStickerSize = 50.0,
      this.maxStickerSize = 200.0,
      this.stickerControlsStyle,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ImageStickersState();
  }
}

class _ImageStickersState extends State<ImageStickers> {
  ImageStream? _backgroundImageStream;
  ImageInfo? _backgroundImageInfo;

  Map<UISticker, _DrawableSticker> stickerMap = {};

  @override
  void initState() {
    super.initState();
    _getBackgroundImage();
    _getImages(widget.stickerList);
  }

  /// I want to support BlendMode for images and I draw images in CustomPainter.
  /// So I resolve all the [ImageProvider] here and update state when image is
  /// resolved.
  void _getImages(List<UISticker> stickerList) async {
    var oldStickers = stickerMap;
    stickerMap = {};

    for (var sticker in stickerList) {
      var drawableSticker = oldStickers[sticker] ?? _DrawableSticker(sticker);
      oldStickers.remove(sticker);
      var stickerImageStream =
          sticker.imageProvider.resolve(ImageConfiguration.empty);
      if (stickerImageStream.key != drawableSticker.imageStream?.key) {
        if (drawableSticker.listener != null) {
          drawableSticker.imageStream
              ?.removeListener(drawableSticker.listener!);
        }
        drawableSticker.imageInfo?.dispose();

        drawableSticker.listener =
            ImageStreamListener((ImageInfo image, bool synchronousCall) {
          setState(() {
            drawableSticker.imageInfo = image;
          });
        });

        drawableSticker.imageStream = stickerImageStream;
        drawableSticker.imageStream!.addListener(drawableSticker.listener!);
      }
      stickerMap[sticker] = drawableSticker;
    }
    for (var element in oldStickers.values) {
      element.imageInfo?.dispose();
    }
  }

  void _getBackgroundImage() {
    final ImageStream? oldImageStream = _backgroundImageStream;
    _backgroundImageStream =
        widget.backgroundImage.resolve(ImageConfiguration.empty);
    if (_backgroundImageStream!.key != oldImageStream?.key) {
      final ImageStreamListener listener =
          ImageStreamListener(_updateBackgroundImage);
      oldImageStream?.removeListener(listener);
      _backgroundImageStream!.addListener(listener);
    }
  }

  void _updateBackgroundImage(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _backgroundImageInfo?.dispose();
      _backgroundImageInfo = imageInfo;
    });
  }

  /// We might need to resolve images again after widget update.
  @override
  void didUpdateWidget(ImageStickers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backgroundImage != oldWidget.backgroundImage) {
      _getBackgroundImage();
    }
    _getImages(widget.stickerList);
  }

  @override
  void dispose() {
    _backgroundImageStream
        ?.removeListener(ImageStreamListener(_updateBackgroundImage));
    _backgroundImageInfo?.dispose();
    _backgroundImageInfo = null;

    for (var element in stickerMap.values) {
      element.imageInfo?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loadedStickers =
        stickerMap.values.where((element) => element.imageInfo != null);
    var editableStickers = loadedStickers
        .where((element) => element.editable)
        .map((sticker) => _EditableSticker(
              sticker: sticker,
              onStateChanged: (isDragged) {
                setState(() {});
              },
              maxStickerSize: widget.maxStickerSize,
              minStickerSize: widget.minStickerSize,
              stickerControlsStyle: widget.stickerControlsStyle,
            ))
        .toList();

    return Stack(
      children: [
        LayoutBuilder(
          builder: (_, constraints) => SizedBox(
            width: constraints.widthConstraints().maxWidth,
            height: constraints.heightConstraints().maxHeight,
            child: _backgroundImageInfo == null
                ? Container()
                : CustomPaint(
                    painter: _DropPainter(
                        _backgroundImageInfo!.image, loadedStickers.toList()),
                  ),
          ),
        ),
        ...editableStickers
      ],
    );
  }
}

class _EditableSticker extends StatefulWidget {
  final _DrawableSticker sticker;
  final Function(bool isDragged)? onStateChanged;
  final double minStickerSize;
  final double maxStickerSize;

  final ImageStickersControlsStyle? stickerControlsStyle;

  const _EditableSticker(
      {required this.sticker,
      required this.minStickerSize,
      required this.maxStickerSize,
      this.onStateChanged,
      this.stickerControlsStyle,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EditableStickerState();
  }
}

class _EditableStickerState extends State<_EditableSticker> {
  late ImageStickersControlsStyle controlsStyle;

  @override
  void initState() {
    super.initState();
    controlsStyle = widget.stickerControlsStyle ?? ImageStickersControlsStyle();
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.sticker.size;
    double width =
        (widget.sticker.size / widget.sticker.imageInfo!.image.height) *
            widget.sticker.imageInfo!.image.width;

    Widget stickerDraggableChild = Transform.rotate(
        angle: widget.sticker.angle,
        child: SizedBox(
          width: width,
          height: height,
          child: Image(
            image: widget.sticker.imageProvider,
          ),
        ));
    Widget draggableEmptyWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(150), width: 1)),
    );
    return Positioned(
      left: widget.sticker.x - width / 2 - controlsStyle.size,
      top: widget.sticker.y - height / 2 - controlsStyle.size,
      child: _buildStickerControls(
          child: Draggable(
            child: draggableEmptyWidget,
            feedback: stickerDraggableChild,
            childWhenDragging: Container(),
            onDragEnd: (dragDetails) {
              setState(() {
                widget.sticker.dragged = false;
                widget.sticker.x = dragDetails.offset.dx + width / 2;
                widget.sticker.y = dragDetails.offset.dy + height / 2;

                widget.onStateChanged?.call(false);
              });
            },
            onDragStarted: () {
              setState(() {
                widget.sticker.dragged = true;
                //todo update in parent in onChanged?
                widget.onStateChanged?.call(true);
              });
            },
          ),
          width: width,
          height: height),
    );
  }

  Widget _buildStickerControls(
      {required Widget child, required double height, required double width}) {
    return Transform.rotate(
        angle: widget.sticker.angle,
        child: SizedBox(
          width: width + controlsStyle.size * 2,
          height: height + controlsStyle.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child,
              Visibility(
                  visible: !widget.sticker.dragged,
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Stack(
                      children: [
                        GestureDetector(
                          child: _buildControlsThumb(),
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: onControlPanUpdate,
                        )
                      ],
                    ),
                  ))
            ],
          ),
        ));
  }

  Widget _buildControlsThumb() => Container(
        width: controlsStyle.size,
        height: controlsStyle.size,
        decoration: BoxDecoration(
            color: controlsStyle.color,
            borderRadius: controlsStyle.borderRadius ??
                BorderRadius.circular(controlsStyle.size / 2)),
        child: controlsStyle.child ?? Container(),
      );

  void onControlPanUpdate(DragUpdateDetails details) {
    Offset centerOfGestureDetector = Offset(widget.sticker.x, widget.sticker.y);
    final touchPositionFromCenter =
        details.globalPosition - centerOfGestureDetector;
    setState(() {
      var size = (math.max(touchPositionFromCenter.dx.abs(),
                  touchPositionFromCenter.dy.abs()) -
              controlsStyle.size) * 2;
      size = size.clamp(widget.minStickerSize, widget.maxStickerSize);
      widget.sticker.size = size;
      widget.sticker.angle =
          touchPositionFromCenter.direction - (45 * math.pi / 180);
    });
  }
}

class _DropPainter extends CustomPainter {
  ui.Image? weaponImage;
  List<_DrawableSticker> stickerList;

  _DropPainter(this.weaponImage, this.stickerList);

  @override
  void paint(Canvas canvas, Size size) {
    size = Size(size.width, size.height);
    Rect r = Offset.zero & size;
    Paint paint = Paint();
    if (weaponImage != null) {
      Size inputSize =
          Size(weaponImage!.width.toDouble(), weaponImage!.height.toDouble());
      FittedSizes fs = applyBoxFit(BoxFit.contain, inputSize, size);
      Rect src = Offset.zero & fs.source;
      Rect dst = Alignment.center.inscribe(fs.destination, r);
      canvas.saveLayer(dst, Paint());
      canvas.drawImageRect(weaponImage!, src, dst, paint);
      for (var sticker in stickerList) {
        drawSticker(canvas, size, sticker);
      }
      canvas.restore();
    }
  }

  void drawSticker(Canvas canvas, Size size, _DrawableSticker sticker) {
    if (!sticker.dragged) {
      canvas.save();

      double height = sticker.size;
      double width = (sticker.size / sticker.imageInfo!.image.height) *
          sticker.imageInfo!.image.width;

      Paint stickerPaint = Paint();
      stickerPaint.blendMode = sticker.blendMode;
      stickerPaint.color = Colors.black.withAlpha(240);

      Size inputSize = Size(sticker.imageInfo!.image.width.toDouble(),
          sticker.imageInfo!.image.height.toDouble());

      FittedSizes fs =
          applyBoxFit(BoxFit.contain, inputSize, Size(width, height));
      Rect src = Offset.zero & fs.source;
      Rect dst = Offset(sticker.x - width / 2, sticker.y - height / 2) &
          fs.destination;

      canvas.translate(sticker.x, sticker.y);
      canvas.rotate(sticker.angle);
      canvas.translate(-sticker.x, -sticker.y);
      canvas.drawImageRect(sticker.imageInfo!.image, src, dst, stickerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) => false;
}

/// A proxy for UISticker to store ImageStream and ImageInfo
/// after ImageProvider resolve
class _DrawableSticker {
  final UISticker _sticker;
  bool dragged;
  ImageStream? imageStream;
  ImageInfo? imageInfo;
  ImageStreamListener? listener;

  _DrawableSticker(this._sticker, {this.dragged = false});

  double get x => _sticker.x;

  set x(double x) {
    _sticker.x = x;
  }

  double get y => _sticker.y;

  set y(double y) {
    _sticker.y = y;
  }

  double get size => _sticker.size;

  set size(double size) {
    _sticker.size = size;
  }

  double get angle => _sticker.angle;

  set angle(double angle) {
    _sticker.angle = angle;
  }

  bool get editable => _sticker.editable;

  BlendMode get blendMode => _sticker.blendMode;

  ImageProvider get imageProvider => _sticker.imageProvider;
}
