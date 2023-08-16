import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:gooftuber_editor/views/editor/utils.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;
import 'package:mockito/mockito.dart';

class MockFilePicker extends Mock implements FilePicker {}

void main() {
  group('handleFileDrop', () {
    flutter_test.testWidgets('does not add a sprite if the file is not a PNG',
        (tester) async {
      final file = XFile('test.txt');
      final details = DropDoneDetails(
          files: [file],
          globalPosition: Offset.zero,
          localPosition: Offset.zero);
      final sprites = <Image>[];
      await tester.runAsync(() async {
        await handleFileDrop(details, (fn) => fn());
      });
      expect(sprites.length, equals(0));
    });
  });

  group('byte ops', () {
    testWidgets('Image <> PNG', (tester) async {
      List<List<painter.Pixel>> pixels = [];
      for (int i = 0; i < 10; i++) {
        pixels.add([]);
        for (int j = 0; j < 10; j++) {
          pixels[i].add(painter.Pixel(Colors.black));
        }
      }
      painter.Image image = painter.Image("Test", 10, 10, pixels, painter.FrameTypes.talking);
      List<int> bytes = image.saveAsPng();

      // try to load the image
      List<List<painter.Pixel>> loaded = painter.loadFromPng(bytes);
      // iterate through the pixels and compare
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
          expect(pixels[i][j].color, equals(loaded[i][j].color));
        }
      }
    });
  });
}
