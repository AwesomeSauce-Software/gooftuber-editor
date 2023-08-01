// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

void saveFileOnWeb(Uint8List bytes, String filename) {
  var blob = Blob([bytes]);
  var url = Url.createObjectUrlFromBlob(blob);
  var anchor = document.createElement('a') as AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = filename;
  document.body!.children.add(anchor);
  anchor.click();
  document.body!.children.remove(anchor);
  Url.revokeObjectUrl(url);
}