## Flutter Package to apply stickers to image.

![Demo](https://raw.githubusercontent.com/Koallider/image_stickers/development/doc/demo.gif)

Try [Demo](https://koallider.github.io/image_stickers/).

## Getting Started
### Installation

```yaml
dependencies:
  ...
  image_stickers: 0.0.5
```

### Usage

```dart
ImageStickers(
  backgroundImage: const AssetImage("assets/background.png"),
  stickerList: [
    UISticker(
      imageProvider: const AssetImage("assets/sticker.png"),
      x: 100,
      y: 100,
      editable: true)
  ],
)
```
