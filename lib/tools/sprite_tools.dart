import 'package:pixelart/main.dart';

import '../painter.dart';

bool doesPrimarySpriteExist() {
  for (Image image in sprites) {
    if (image.frameType == FrameTypes.nontalking || image.frameType == FrameTypes.talking) {
      return true;
    }
  }
  return false;
}

Image? getPrimaryImage() {
    for (int i = 0; i < sprites.length; i++) {
      if (sprites[i].frameType == FrameTypes.nontalking || sprites[i].frameType == FrameTypes.talking) return sprites[i];
    }
    return null;
  }

Image copyImage(Image image) {
  // we need to copy the image so that we don't modify the original
  List<List<Pixel>> pixels = [];
  for (int y = 0; y < image.height; y++) {
    pixels.add([]);
    for (int x = 0; x < image.width; x++) {
      pixels[y].add(Pixel(image.pixels[y][x].color, empty: image.pixels[y][x].empty));
    }
  }
  return Image(image.name, image.width, image.height, pixels, image.frameType);
}