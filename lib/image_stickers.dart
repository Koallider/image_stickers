library image_stickers;

import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ImageStickers extends StatefulWidget {
  final String backgroundImage;
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
    return ImageStickersState();
  }
}

class ImageStickersState extends State<ImageStickers> {
  ui.Image? backgroundImage;

  List<_DrawableSticker> drawableStickers = [];

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() async {
    var imageBytes = await rootBundle.load(widget.backgroundImage);
    backgroundImage = await decodeImageFromList(imageBytes.buffer
        .asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));

    drawableStickers = await Future.wait(widget.stickerList.map((e) async {
      var stickerImageBytes = await rootBundle.load(e.imagePath);
      var image = await decodeImageFromList(stickerImageBytes.buffer
          .asUint8List(stickerImageBytes.offsetInBytes,
              stickerImageBytes.lengthInBytes));
      return _DrawableSticker(e, false, image);
    }).toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var stickers = drawableStickers
        .map((sticker) => EditableSticker(
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
                    painter: DropPainter(backgroundImage!, drawableStickers),
                  ),
          ),
        ),
        ...stickers.where((e) => e.sticker.sticker.editable)
      ],
    );
  }
}

class EditableSticker extends StatefulWidget {
  final _DrawableSticker sticker;
  final Function(bool isDragged)? onStateChanged;
  final double minStickerSize;
  final double maxStickerSize;

  const EditableSticker(
      {required this.sticker,
      required this.minStickerSize,
      required this.maxStickerSize,
      this.onStateChanged,
      Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EditableStickerState();
  }
}

class EditableStickerState extends State<EditableSticker> {
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
          child: Image.asset(widget.sticker.sticker.imagePath),
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
                      widget.sticker.sticker.x =
                          dragDetails.offset.dx + width / 2;
                      widget.sticker.sticker.y =
                          dragDetails.offset.dy + height / 2;

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
    Widget rotateControlWidget = Container(
      width: controlsSize,
      height: controlsSize,
      decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(controlsSize / 2)),
    );

    return Transform.rotate(
        angle: widget.sticker.sticker.angle,
        child: SizedBox(
          width: width + controlsSize * 2,
          height: height + controlsSize * 2,
          child: Stack(
            children: [
              Center(
                child: child,
              ),
              Visibility(
                  visible: !widget.sticker.dragged,
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          child: rotateControlWidget,
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) {
                            //rotation of the widget
                            Offset centerOfGestureDetector = Offset(
                                widget.sticker.sticker.x,
                                widget.sticker.sticker.y);
                            final touchPositionFromCenter =
                                details.globalPosition -
                                    centerOfGestureDetector;
                            setState(() {
                              var size = (math.max(
                                          touchPositionFromCenter.dx.abs(),
                                          touchPositionFromCenter.dy.abs()) -
                                      controlsSize) * 2;
                              size = size.clamp(
                                  widget.minStickerSize, widget.maxStickerSize);
                              widget.sticker.sticker.size = size;
                              widget.sticker.sticker.angle =
                                  touchPositionFromCenter.direction -
                                      (45 * math.pi / 180);
                            });
                          },
                        )
                      ],
                    ),
                  ))
            ],
          ),
        ));
  }
}

class DropPainter extends CustomPainter {
  ui.Image? weaponImage;
  List<_DrawableSticker> stickerList;

  final topOffset = 85.0;
  final bottomOffset = 65.0;
  final sideOffset = 8.0;

  DropPainter(this.weaponImage, this.stickerList);

  @override
  void paint(Canvas canvas, Size size) {
    size = Size(
        size.width - sideOffset * 2, size.height - topOffset - bottomOffset);
    Rect r = Offset(sideOffset, topOffset) & size;
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
      stickerPaint.blendMode = BlendMode.srcATop;
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
  bool shouldRepaint(DropPainter oldDelegate) => false;
}

class _DrawableSticker {
  UISticker sticker;
  bool dragged;
  ui.Image image;

  _DrawableSticker(this.sticker, this.dragged, this.image);
}

class UISticker {
  String imagePath;
  double x;
  double y;
  double size;
  double angle;

  bool editable = false;

  UISticker(
      {required this.imagePath,
      required this.x,
      required this.y,
      this.size = 100,
      this.angle = 0.0,
      this.editable = false});
}
