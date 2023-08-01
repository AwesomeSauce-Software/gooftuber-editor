import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pixelart/painter.dart' as painter;
import 'package:pixelart/tools/platformtools.dart';
import 'package:pixelart/tools/webtools.dart';

import '../dialogs.dart';
import '../main.dart';

/* 
JSON FORMAT:
{
    "avatars": [
        {
            "filename": "",
            "base64": ""
        }
    ]
}
*/

String exportJson(List<painter.Image> images) {
  List<Map<String, String>> avatars = [];
  for (painter.Image image in images) {
    var name = image.name;
    if (image.frameType == painter.FrameTypes.talking) {
      name = 'talking';
    } else if (image.frameType == painter.FrameTypes.nontalking) {
      name = 'nontalking';
    }
    avatars.add(
        {"filename": name, "base64": base64Encode(image.saveAsPng())});
  }
  return jsonEncode({"avatars": avatars});
}

List<painter.Image> importJson(context, String json) {
  List<painter.Image> images = [];
  try {
    Map<String, dynamic> data = jsonDecode(json);
    for (Map<String, dynamic> avatar in data["avatars"]) {
      var pixels = painter.loadFromPng(base64Decode(avatar["base64"]!));
      if (avatar["filename"]!.replaceAll('.png', '').toLowerCase() == 'talking' ||
          avatar["filename"]!.replaceAll('.png', '').toLowerCase() == 'nontalking') {
        images.add(painter.Image(
            '',
            pixels[0].length,
            pixels.length,
            pixels,
            avatar["filename"]!.replaceAll('.png', '').toLowerCase() == 'talking'
                ? painter.FrameTypes.talking
                : painter.FrameTypes.nontalking));
        continue;
      } else {
        images.add(painter.Image(avatar["filename"]!, pixels[0].length,
            pixels.length, pixels, painter.FrameTypes.expression));
      }
    }
    return images;
  } catch (e) {
    showSnackbar(context, 'Error importing file!');
    return [];
  }
}

Future<void> exportFile(BuildContext context, String json) async {
  // save as dialog
  if (sprites.isEmpty) {
    showSnackbar(context, 'Sprites are empty, nothing to export!');
    return;
  }

  if (isPlatformWeb()) {
    saveFileOnWeb(Uint8List.fromList(utf8.encode(json)), 'avatar.avatar');
    return;
  }

  String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Avatar',
      allowedExtensions: ['avatar'],
      fileName: 'avatar.avatar');
  if (outputFile == null) {
    return;
  } else {
    List<int> bytes = utf8.encode(json);
    await File(outputFile).writeAsBytes(bytes);
  }
  lastSaved = DateTime.now().millisecondsSinceEpoch;
  updater.value++;
}

Future<List<painter.Image>> importFile(context) async {
  if (sprites.isNotEmpty) {
    if (await showConfirmDialog(context, 'Importing',
        'Importing will overwrite your current sprites, are you sure?')) {
      sprites.clear();
    } else {
      return [];
    }
  }
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['avatar']);
  if (result == null) {
    return [];
  }
  if (isPlatformWeb()) {
    // parse result.files.single.bytes to string
    var text = utf8.decode(result.files.single.bytes!);
    return importJson(context, text);
  } else {
    File file = File(result.files.single.path!);
  String json = await file.readAsString();
  return importJson(context, json);
  }
}

Future<void> saveFile(bool overidePath) async {
  // save as dialog
  if (sprites.isEmpty) {
    return;
  }
  if (imageSelected.value < 0) {
    imageSelected.value = 0;
  }

  if (isPlatformWeb()) {
    var name = sprites[imageSelected.value].name;
  if (sprites[imageSelected.value].frameType == painter.FrameTypes.talking) {
    name = 'talking';
  } else if (sprites[imageSelected.value].frameType ==
      painter.FrameTypes.nontalking) {
    name = 'nontalking';
  }
    saveFileOnWeb(Uint8List.fromList(sprites[imageSelected.value].saveAsPng()), '$name.png');
    return;
  }

  if (!overidePath && sprites[imageSelected.value].path != '') {
    List<int> bytes = sprites[imageSelected.value].saveAsPng();
    await File(sprites[imageSelected.value].path).writeAsBytes(bytes);
    lastSaved = DateTime.now().millisecondsSinceEpoch;
    updater.value++;
    return;
  }
  var name = sprites[imageSelected.value].name;
  if (sprites[imageSelected.value].frameType == painter.FrameTypes.talking) {
    name = 'talking';
  } else if (sprites[imageSelected.value].frameType ==
      painter.FrameTypes.nontalking) {
    name = 'nontalking';
  }
  String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save avatar Frame',
      allowedExtensions: ['png'],
      fileName: '$name.png');
  if (outputFile == null) {
    return;
  } else {
    sprites[imageSelected.value].path = outputFile;
    List<int> bytes = sprites[imageSelected.value].saveAsPng();
    await File(outputFile).writeAsBytes(bytes);
  }
  lastSaved = DateTime.now().millisecondsSinceEpoch;
  updater.value++;
}
