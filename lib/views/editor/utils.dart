import 'package:desktop_drop/desktop_drop.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;

Future<void> handleFileDrop(DropDoneDetails details, void Function(void Function()) setState) async {
    for (var file in details.files) {
      if (!file.name.endsWith('.png')) {
        continue;
      }
      var type = (file.name.replaceAll('.png', '').toLowerCase() == "talking")
          ? painter.FrameTypes.talking
          : (file.name.replaceAll('.png', '').toLowerCase() == "nontalking")
              ? painter.FrameTypes.nontalking
              : painter.FrameTypes.expression;
      var bytes = await file.readAsBytes();
      var pixels = painter.loadFromPng(bytes);
      var image = painter.Image(
          (type == painter.FrameTypes.expression)
              ? file.name.replaceAll('.png', '')
              : '',
          pixels[0].length,
          pixels.length,
          pixels,
          type);
      setState(() {
        sprites.add(image);
      });
    }
  }

  void refresh() {
    Future.delayed(const Duration(seconds: 1), () {
      // clear redo and undo above 10 to save memory
      if (spriteBefore.value.length > 10) {
        spriteBefore.value.removeRange(10, spriteBefore.value.length);
      }
      if (spriteRedo.value.length > 10) {
        spriteRedo.value.removeRange(10, spriteRedo.value.length);
      }
      var toUpdate = updater.value++;
      if (toUpdate > 100) {
        toUpdate = 0;
      }
      if (undoRedo.value > 100) {
        undoRedo.value = 0;
      }
      updater.value = toUpdate;
      // check if last save was more than 5 mins ago and autoSave enabled
      if (autoSave.value && (DateTime.now().millisecondsSinceEpoch - lastSaved) > 300000) {
        saveProject();
      }
      refresh();
    });
  }

  bool isEnabled() {
    return sprites.isNotEmpty && imageSelected.value >= 0;
  }