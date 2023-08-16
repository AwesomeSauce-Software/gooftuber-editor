import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/views/painter.dart';
import 'package:gooftuber_editor/tools/sprite_tools.dart';

void main() {
  group('doesPrimarySpriteExist', () {
    test('returns true if talking sprite exists', () {
      List<List<Pixel>> pixels = [];
      for (int i = 0; i < 128; i++) {
        pixels.add([]);
        for (int j = 0; j < 128; j++) {
          pixels[i].add(Pixel(const Color(0xFF000000)));
        }
      }
      sprites = [
        Image("", 128, 128, pixels, FrameTypes.talking),
        Image("", 128, 128, pixels, FrameTypes.nontalking),
      ];
      expect(doesPrimarySpriteExist(), isTrue);
    });

    sprites.clear();

    test('returns false if no primary exists', () {
      sprites = [
        Image("", 128, 128, [], FrameTypes.talking),
      ];
      expect(doesPrimarySpriteExist(), isTrue);
    });

    test('returns false if no sprites exist', () {
      sprites = [];
      expect(doesPrimarySpriteExist(), isFalse);
    });
  });

  group('getPrimaryImage', () {
    test('returns first non-talking sprite if it exists', () {
      List<List<Pixel>> pixels = [];
      for (int i = 0; i < 128; i++) {
        pixels.add([]);
        for (int j = 0; j < 128; j++) {
          pixels[i].add(Pixel(const Color(0xFF000000)));
        }
      }
      sprites = [
        Image("", 128, 128, pixels, FrameTypes.talking),
        Image("", 128, 128, pixels, FrameTypes.nontalking),
      ];
      expect(getPrimaryImage(), equals(sprites.first));
    });

    test('returns null if no sprites exist', () {
      sprites = [];
      expect(getPrimaryImage(), isNull);
    });
  });

  group('copyImage', () {
    test('returns a copy of the input image', () {
      final original = Image(
        "aaa",
        1,
        1,
        [
          [Pixel(const Color(0xFF000000))],
        ],
        FrameTypes.expression,
      );
      final copy = copyImage(original);
      expect(copy, isNot(same(original)));
      // edit original
      original.pixels[0][0] = Pixel(const Color(0xFFFFFFFF));
      expect(copy.pixels[0][0].color, equals(const Color(0xFF000000)));
    });
  });

  group('image checks', () {
    test('is image empty?', () {
      final image = Image(
        "aaa",
        1,
        1,
        [
          [Pixel(const Color(0xFF000000))],
        ],
        FrameTypes.expression,
      );
      expect(isImageEmpty(image), isFalse);
      image.pixels[0][0] = Pixel(const Color(0x00000000));
      expect(isImageEmpty(image), isTrue);
    });
  });
}