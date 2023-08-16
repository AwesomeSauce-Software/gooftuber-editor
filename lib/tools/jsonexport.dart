import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:gooftuber_editor/tools/webtools.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/dialogs.dart';
import '../main.dart';

String exportJson(List<painter.Image> images) {
  List<Map<String, String>> avatars = [];
  for (painter.Image image in images) {
    var name = image.name;
    if (image.frameType == painter.FrameTypes.talking) {
      name = 'talking.png';
    } else if (image.frameType == painter.FrameTypes.nontalking) {
      name = 'nontalking.png';
    }
    avatars.add({"filename": name, "base64": base64Encode(image.saveAsPng())});
  }
  return jsonEncode({"avatars": avatars});
}

List<painter.Image> importJson(context, String json) {
  List<painter.Image> images = [];
  try {
    Map<String, dynamic> data = jsonDecode(json);
    for (Map<String, dynamic> avatar in data["avatars"]) {
      var pixels = painter.loadFromPng(base64Decode(avatar["base64"]!));
      if (avatar["filename"]!.replaceAll('.png', '').toLowerCase() ==
              'talking' ||
          avatar["filename"]!.replaceAll('.png', '').toLowerCase() ==
              'nontalking') {
        images.add(painter.Image(
            '',
            pixels[0].length,
            pixels.length,
            pixels,
            avatar["filename"]!.replaceAll('.png', '').toLowerCase() ==
                    'talking'
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

Future<void> importPalettePng(context, Uint8List bytes, name) async {
  var palette = painter.ColorPalette.fromPng(bytes, name);
  colorPalettes.add(palette);
  saveColorPalettes();
}

Future<void> handleImportPaletteDrop(context, DropDoneDetails details,
    void Function(void Function()) setState) async {
  for (var file in details.files) {
    if (!file.name.endsWith('.png') || !file.name.endsWith('.json')) {
      continue;
    }

    var bytes = await file.readAsBytes();

    if (file.name.endsWith('.png')) {
      importPalettePng(context, bytes, file.name.replaceAll('.png', ''));
    } else if (file.name.endsWith('.json')) {
      var text = utf8.decode(bytes);
      var palette = painter.ColorPalette.fromJson(jsonDecode(text));
      colorPalettes.add(palette);
      saveColorPalettes();
    }
  }
}

Future<void> importPalette(context) async {
  FilePickerResult? result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['json', 'png']);
  if (result == null) {
    return;
  }

  if (result.files.single.extension == 'png') {
    if (isPlatformWeb()) {
      return importPalettePng(context, result.files.single.bytes!,
          result.files.single.name.replaceAll('.png', ''));
    } else {
      File file = File(result.files.single.path!);
      file.readAsBytes().then((bytes) {
        importPalettePng(
            context, bytes, result.files.single.name.replaceAll('.png', ''));
      });
    }

    return;
  }

  if (isPlatformWeb()) {
    // parse result.files.single.bytes to string
    var text = utf8.decode(result.files.single.bytes!);
    var palette = painter.ColorPalette.fromJson(jsonDecode(text));
    colorPalettes.add(palette);
    saveColorPalettes();
  } else {
    File file = File(result.files.single.path!);
    file.readAsString().then((String json) {
      var palette = painter.ColorPalette.fromJson(jsonDecode(json));
      colorPalettes.add(palette);
      saveColorPalettes();
    });
  }
}

Future<void> exportString(BuildContext context, String json, String filename,
    List<String> filetypes) async {
  // save as dialog
  if (isPlatformWeb()) {
    saveFileOnWeb(Uint8List.fromList(utf8.encode(json)), filename);
    return;
  }

  String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save as', allowedExtensions: filetypes, fileName: filename);
  if (outputFile == null) {
    return;
  } else {
    List<int> bytes = utf8.encode(json);
    await File(outputFile).writeAsBytes(bytes);
  }
}

Future<void> exportBytes(BuildContext? context, Uint8List bytes,
    String filename, List<String> filetypes) async {
  // save as dialog
  if (isPlatformWeb()) {
    saveFileOnWeb(bytes, filename);
    return;
  }

  String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save as', allowedExtensions: filetypes, fileName: filename);
  if (outputFile == null) {
    return;
  } else {
    await File(outputFile).writeAsBytes(bytes);
  }
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

Future<void> loadProject(context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString("project") != null) {
    sprites = importJson(context, prefs.getString("project")!);
    updater.value++;
  }
  return;
}

Future<void> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  autoSave.value = prefs.getBool("autoSave") ?? false;
  appTheme.value = prefs.getInt("theme") ?? 2;
  disableOnlineFeatures.value = prefs.getBool("offline") ?? false;
  familiarityMode.value = prefs.getBool("familiarity") ?? false;

  if (prefs.getStringList("colorPalettes") != null) {
    List<String> jsonList = prefs.getStringList("colorPalettes")!;
    colorPalettes = jsonList
        .map((palette) => painter.ColorPalette.fromJson(
            jsonDecode(palette) as Map<String, dynamic>))
        .toList();
  }
  return;
}

Future<void> saveSettings() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool("autoSave", autoSave.value);
  prefs.setInt("theme", appTheme.value);
  prefs.setBool("offline", disableOnlineFeatures.value);
  prefs.setBool("familiarity", familiarityMode.value);
  return;
}

Future<void> saveColorPalettes() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> jsonList =
      colorPalettes.map((palette) => jsonEncode(palette)).toList();
  prefs.setStringList("colorPalettes", jsonList);
  return;
}

Future<void> saveProject() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString("project", exportJson(sprites));
  lastSaved = DateTime.now().millisecondsSinceEpoch;
  return;
}

Future<void> saveFile(int image) async {
  // save as dialog
  if (sprites.isEmpty) {
    return;
  }

  if (isPlatformWeb()) {
    var name = sprites[image].name;
    if (sprites[image].frameType == painter.FrameTypes.talking) {
      name = 'talking';
    } else if (sprites[image].frameType == painter.FrameTypes.nontalking) {
      name = 'nontalking';
    }
    saveFileOnWeb(Uint8List.fromList(sprites[image].saveAsPng()), '$name.png');
    return;
  }

  if (sprites[image].path != '') {
    List<int> bytes = sprites[image].saveAsPng();
    await File(sprites[image].path).writeAsBytes(bytes);
    lastSaved = DateTime.now().millisecondsSinceEpoch;
    updater.value++;
    return;
  }
  var name = sprites[image].name;
  if (sprites[image].frameType == painter.FrameTypes.talking) {
    name = 'talking';
  } else if (sprites[image].frameType == painter.FrameTypes.nontalking) {
    name = 'nontalking';
  }
  String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save avatar Frame',
      allowedExtensions: ['png'],
      fileName: '$name.png');
  if (outputFile == null) {
    return;
  } else {
    sprites[image].path = outputFile;
    List<int> bytes = sprites[image].saveAsPng();
    await File(outputFile).writeAsBytes(bytes);
  }
  updater.value++;
}
