import 'package:flutter/material.dart';
import 'package:image_stickers/image_stickers.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageStickers(
        backgroundImage: "assets/weapon.png",
        stickerList: [
          UISticker(imagePath: "assets/sticker.png", x: 100, y: 100, editable: true, angle: 90)
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
