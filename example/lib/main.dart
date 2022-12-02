import 'package:flutter/material.dart';
import 'package:image_stickers/image_stickers.dart';
import 'package:image_stickers/image_stickers_controls_style.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<UISticker> stickers = [];

  @override
  void initState() {
    stickers.add(createSticker(0));
  }

  UISticker createSticker(int index) {
    return UISticker(
        imageProvider: const AssetImage("assets/sticker.png"),
        x: 100 + 100.0 * index,
        y: 360,
        editable: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        stickers.add(createSticker(stickers.length));
                      });
                    },
                    child: const Text("Add sticker")),
              ],
            ),
            Expanded(flex: 7, child: Container(
              child: ImageStickers(
                backgroundImage: const AssetImage("assets/car.png"),
                stickerList: stickers,
                stickerControlsStyle: ImageStickersControlsStyle(
                    color: Colors.blueGrey,
                    child: const Icon(
                      Icons.zoom_out_map,
                      color: Colors.white,
                    )),
              ),
            )),
            Expanded(flex: 3, child: Container())
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
