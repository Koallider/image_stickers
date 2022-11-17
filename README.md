## Flutter Package to apply stickers to image.

## Getting Started
### Installation

```yaml
dependencies:
  ...
  image_stickers: 0.0.1
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
