library image_stickers;

import 'dart:core';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as UI;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as IMAGE;
import 'package:flutter/material.dart';

class ImageStickers extends StatefulWidget {
  final String backgroundImage;
  final List<UISticker> stickerList;

  const ImageStickers(
      {required this.backgroundImage, required this.stickerList, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImageStickersState();
  }
}

class ImageStickersState extends State<ImageStickers> {
  UI.Image? backgroundImage;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() async {
    var imageBytes = await rootBundle.load(widget.backgroundImage);
    backgroundImage = await decodeImageFromList(imageBytes.buffer
        .asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));

    for (UISticker uiSticker in widget.stickerList) {
      var stickerImageBytes = await rootBundle.load(uiSticker.imagePath);
      uiSticker.image = await decodeImageFromList(stickerImageBytes.buffer
          .asUint8List(stickerImageBytes.offsetInBytes,
              stickerImageBytes.lengthInBytes));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ////debugPrint("build $weaponImage");
    var stackWidgets = <Widget>[];
    stackWidgets.add(LayoutBuilder(
      // Inner yellow container
      builder: (_, constraints) => SizedBox(
        width: constraints.widthConstraints().maxWidth,
        height: constraints.heightConstraints().maxHeight,
        //color: Colors.yellow,
        child: backgroundImage == null
            ? Container()
            : Container(
                child: CustomPaint(
                  painter: DropPainter(backgroundImage!, widget.stickerList),
                ),
              ),
      ),
    ));
    stackWidgets.addAll(widget.stickerList
        .map((e) => e.image == null
            ? Container()
            : UIStickerWidget(e, () {
                setState(() {});
              }))
        .toList());
    return Stack(
      children: stackWidgets,
    );
  }
}

class UIStickerWidget extends StatefulWidget {
  final UISticker uiSticker;
  final Function updateParent;

  const UIStickerWidget(this.uiSticker, this.updateParent,
      {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UIStickerWidgetState();
  }
}

class UIStickerWidgetState extends State<UIStickerWidget> {
  final controlsSize = 30.0;

  double minStickerSize = 50.0;
  double maxStickerSize = 200.0;

  final topOffset = 85.0;
  final bottomOffset = 65.0;
  final sideOffset = 8.0;

  double extraSideOffset = 0.0;
  double extraTopOffset = 0.0;
  double realImageHeight = 0.0;
  double realImageWidth = 0.0;

  bool isCharmConnected = false;

  @override
  void initState() {
    minStickerSize = 50.0;
    maxStickerSize = 200.0;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = widget.uiSticker.size;
    double width = (widget.uiSticker.size / widget.uiSticker.image!.height) *
        widget.uiSticker.image!.width;

    Widget stickerDraggableChild = Transform.rotate(
        angle: widget.uiSticker.angle,
        child: SizedBox(
          width: width,
          height: height,
          child: Image.asset(widget.uiSticker.imagePath),
        ));
    Widget draggableEmptyWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(150), width: 1)),
    );
    return widget.uiSticker.editable
        ? Positioned(
            left: widget.uiSticker.x - width / 2 - controlsSize,
            top: widget.uiSticker.y - height / 2 - controlsSize,
            child: buildStickerControls(
                child: Draggable(
                  child: draggableEmptyWidget,
                  feedback: stickerDraggableChild,
                  childWhenDragging: Container(),
                  onDragEnd: (dragDetails) {
                    setState(() {
                      widget.uiSticker.dragging = false;
                      widget.uiSticker.x = dragDetails.offset.dx + width / 2;
                      widget.uiSticker.y = dragDetails.offset.dy + height / 2;

                      widget.updateParent();
                    });
                  },
                  onDragStarted: () {
                    setState(() {
                      widget.uiSticker.dragging = true;
                      widget.updateParent();
                    });
                  },
                ),
                width: width,
                height: height),
          )
        : Container();
  }

  Widget buildStickerControls(
      {required Widget child, required double height, required double width}) {
    Widget rotateControlWidget = Container(
      width: controlsSize,
      height: controlsSize,
      decoration: BoxDecoration(color: Colors.blue),
      /*child: Image(
          image: ImageUtil.getImageSource('IMAGE_resize.png'),
        )*/
    );

    return Transform.rotate(
        angle: widget.uiSticker.angle,
        child: SizedBox(
          width: width + controlsSize * 2,
          height: height + controlsSize * 2,
          child: Stack(
            children: [
              Center(
                child: child,
              ),
              Visibility(
                  visible:
                      !widget.uiSticker.dragging && widget.uiSticker.editable,
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
                            Offset centerOfGestureDetector =
                                Offset(widget.uiSticker.x, widget.uiSticker.y);
                            final touchPositionFromCenter =
                                details.globalPosition -
                                    centerOfGestureDetector;
                            setState(() {
                              var size = (math.max(
                                          touchPositionFromCenter.dx.abs(),
                                          touchPositionFromCenter.dy.abs()) -
                                      controlsSize) *
                                  2;
                              if (size < minStickerSize) {
                                size = minStickerSize;
                              }
                              if (size > maxStickerSize) {
                                size = maxStickerSize;
                              }
                              widget.uiSticker.size = size;
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
  UI.Image? weaponImage;
  List<UISticker> stickerList;

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
      //canvas.save();
      canvas.drawImageRect(weaponImage!, src, dst, paint);
      // paint.blendMode = BlendMode.multiply;
      //canvas.restore();
      for (var sticker in stickerList) {
        drawSticker(canvas, size, sticker);
      }
      canvas.restore();
    }
  }

  void drawSticker(Canvas canvas, Size size, UISticker? sticker) {
    if (sticker != null && !sticker.dragging) {
      canvas.save();

      double height = sticker.size;
      double width =
          (sticker.size / sticker.image!.height) * sticker.image!.width;

      Paint stickerPaint = Paint();
      stickerPaint.blendMode = BlendMode.srcATop;
      stickerPaint.color = Colors.black.withAlpha(240);

      //debugPrint("canvas ${stickerList.length}");
      Size inputSize = Size(
          sticker.image!.width.toDouble(), sticker.image!.height.toDouble());

      FittedSizes fs =
          applyBoxFit(BoxFit.contain, inputSize, Size(width, height));
      Rect src = Offset.zero & fs.source;
      Rect dst = Offset(sticker.x - width / 2, sticker.y - height / 2) &
          fs.destination;

      canvas.translate(sticker.x, sticker.y);
      canvas.rotate(sticker.angle);
      canvas.translate(-sticker.x, -sticker.y);
      canvas.drawImageRect(sticker.image!, src, dst, stickerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(DropPainter oldDelegate) => false;
}

class UISticker {
  String imagePath;
  double x;
  double y;
  double size;
  double angle;

  UI.Image? image;
  bool dragging = false;
  bool editable = false;

  UISticker(
      {required this.imagePath,
      required this.x,
      required this.y,
      this.size = 100,
      this.angle = 0.0,
      this.editable = false});
}
