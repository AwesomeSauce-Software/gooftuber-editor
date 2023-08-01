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