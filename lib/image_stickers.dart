library image_stickers;

import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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

class ImageStickers extends StatefulWidget {
  final ImageProvider backgroundImage;
  final List<UISticker> stickerList;

  final double minStickerSize;
  final double maxStickerSize;

  const ImageStickers(
      {required this.backgroundImage,
      required this.stickerList,
      this.minStickerSize = 50.0,
      this.maxStickerSize = 200.0,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ImageStickersState();
  }
}

class _ImageStickersState extends State<ImageStickers> {
  ui.Image? backgroundImage;

  List<_DrawableSticker> drawableStickers = [];

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() async {
    var imageStream = widget.backgroundImage.resolve(ImageConfiguration.empty);
    imageStream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
      setState(() {
        backgroundImage = image.image;
      });
    }));

    for (var sticker in widget.stickerList) {
      var imageStream = sticker.imageProvider.resolve(ImageConfiguration.empty);
      imageStream.addListener(
          ImageStreamListener((ImageInfo image, bool synchronousCall) {
        setState(() {
          drawableStickers.add(_DrawableSticker(sticker, false, image.image));
        });
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    var stickers = drawableStickers
        .map((sticker) => _EditableSticker(
              sticker: sticker,
              onStateChanged: (isDragged) {
                setState(() {});
              },
              maxStickerSize: widget.maxStickerSize,
              minStickerSize: widget.minStickerSize,
            ))
        .toList();

    return Stack(
      children: [
        LayoutBuilder(
          builder: (_, constraints) => SizedBox(
            width: constraints.widthConstraints().maxWidth,
            height: constraints.heightConstraints().maxHeight,
            child: backgroundImage == null
                ? Container()
                : CustomPaint(
                    painter: _DropPainter(backgroundImage!, drawableStickers),
                  ),
          ),
        ),
        ...stickers.where((e) => e.sticker.sticker.editable)
      ],
    );
  }
}

class _EditableSticker extends StatefulWidget {
  final _DrawableSticker sticker;
  final Function(bool isDragged)? onStateChanged;
  final double minStickerSize;
  final double maxStickerSize;

  const _EditableSticker(
      {required this.sticker,
      required this.minStickerSize,
      required this.maxStickerSize,
      this.onStateChanged,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EditableStickerState();
  }
}

class _EditableStickerState extends State<_EditableSticker> {
  final controlsSize = 30.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.sticker.sticker.size;
    double width = (widget.sticker.sticker.size / widget.sticker.image.height) *
        widget.sticker.image.width;

    Widget stickerDraggableChild = Transform.rotate(
        angle: widget.sticker.sticker.angle,
        child: SizedBox(
          width: width,
          height: height,
          child: Image(
            image: widget.sticker.sticker.imageProvider,
          ),
        ));
    Widget draggableEmptyWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(150), width: 1)),
    );
    return Positioned(
      left: widget.sticker.sticker.x - width / 2 - controlsSize,
      top: widget.sticker.sticker.y - height / 2 - controlsSize,
      child: buildStickerControls(
          child: Draggable(
            child: draggableEmptyWidget,
            feedback: stickerDraggableChild,
            childWhenDragging: Container(),
            onDragEnd: (dragDetails) {
              setState(() {
                widget.sticker.dragged = false;
                widget.sticker.sticker.x = dragDetails.offset.dx + width / 2;
                widget.sticker.sticker.y = dragDetails.offset.dy + height / 2;

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

  Widget buildStickerControls(
      {required Widget child, required double height, required double width}) {
    return Transform.rotate(
        angle: widget.sticker.sticker.angle,
        child: SizedBox(
          width: width + controlsSize * 2,
          height: height + controlsSize * 2,
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
                          child: buildControlsThumb(),
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

  Widget buildControlsThumb() => Container(
        width: controlsSize,
        height: controlsSize,
        decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(controlsSize / 2)),
      );

  void onControlPanUpdate(DragUpdateDetails details) {
    Offset centerOfGestureDetector =
        Offset(widget.sticker.sticker.x, widget.sticker.sticker.y);
    final touchPositionFromCenter =
        details.globalPosition - centerOfGestureDetector;
    setState(() {
      var size = (math.max(touchPositionFromCenter.dx.abs(),
                  touchPositionFromCenter.dy.abs()) -
              controlsSize) *
          2;
      size = size.clamp(widget.minStickerSize, widget.maxStickerSize);
      widget.sticker.sticker.size = size;
      widget.sticker.sticker.angle =
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

      double height = sticker.sticker.size;
      double width =
          (sticker.sticker.size / sticker.image.height) * sticker.image.width;

      Paint stickerPaint = Paint();
      stickerPaint.blendMode = sticker.sticker.blendMode;
      stickerPaint.color = Colors.black.withAlpha(240);

      Size inputSize =
          Size(sticker.image.width.toDouble(), sticker.image.height.toDouble());

      FittedSizes fs =
          applyBoxFit(BoxFit.contain, inputSize, Size(width, height));
      Rect src = Offset.zero & fs.source;
      Rect dst = Offset(
              sticker.sticker.x - width / 2, sticker.sticker.y - height / 2) &
          fs.destination;

      canvas.translate(sticker.sticker.x, sticker.sticker.y);
      canvas.rotate(sticker.sticker.angle);
      canvas.translate(-sticker.sticker.x, -sticker.sticker.y);
      canvas.drawImageRect(sticker.image, src, dst, stickerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) => false;
}

class _DrawableSticker {
  UISticker sticker;
  bool dragged;
  ui.Image image;

  _DrawableSticker(this.sticker, this.dragged, this.image);
}
