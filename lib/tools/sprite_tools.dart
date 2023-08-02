import 'package:flutter/material.dart' as m;
import 'package:gooftuber_editor/main.dart';

import '../views/painter.dart';

bool doesPrimarySpriteExist() {
  return doesTalkingExist() || doesNonTalkingExist();
}

bool doesTalkingExist() {
  for (Image image in sprites) {
    if (image.frameType == FrameTypes.talking) {
      return true;
    }
  }
  return false;
}

bool doesNonTalkingExist() {
  for (Image image in sprites) {
    if (image.frameType == FrameTypes.nontalking) {
      return true;
    }
  }
  return false;
}

Image? getPrimaryImage() {
  for (int i = 0; i < sprites.length; i++) {
    if (sprites[i].frameType == FrameTypes.nontalking ||
        sprites[i].frameType == FrameTypes.talking) return sprites[i];
  }
  return null;
}

Image copyImage(Image image) {
  // we need to copy the image so that we don't modify the original
  List<List<Pixel>> pixels = [];
  for (int y = 0; y < image.height; y++) {
    pixels.add([]);
    for (int x = 0; x < image.width; x++) {
      pixels[y].add(
          Pixel(image.pixels[y][x].color, empty: image.pixels[y][x].empty));
    }
  }
  return Image(image.name, image.width, image.height, pixels, image.frameType);
}

bool isImageEmpty(Image image) {
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (!image.pixels[y][x].empty &&
          image.pixels[y][x].color != m.Colors.transparent) return false;
    }
  }
  return true;
}

redo(Pages currentPage) {
  if (currentPage != Pages.editor || spriteRedo.value.isEmpty) return;
  // redo by using spriteRedo[0]
  spriteBefore.value.add(copyImage(sprites[imageSelected.value]));
  sprites[imageSelected.value] = spriteRedo.value[0];
  spriteRedo.value.removeAt(0);
}

undo(Pages currentPage) {
  if (currentPage != Pages.editor || spriteBefore.value.isEmpty) return;
  // undo by using spriteBefore[0]
  spriteRedo.value.add(copyImage(sprites[imageSelected.value]));
  sprites[imageSelected.value] = spriteBefore.value[0];
  spriteBefore.value.removeAt(0);
}
