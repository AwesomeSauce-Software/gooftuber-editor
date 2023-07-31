import 'dart:io';

import 'package:flutter/foundation.dart';

bool isPlatformWindows() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isWindows;
}

bool isPlatformLinux() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isLinux;
}

bool isPlatformMacos() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isMacOS;
}

bool isPlatformWeb() {
  return kIsWeb;
}

bool isPlatformMobile() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid || Platform.isIOS;
}

bool isPlatformIOS() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isIOS;
}

bool isPlatformAndroid() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid;
}

void exitApp() {
  if (isPlatformWindows() || isPlatformLinux() || isPlatformMacos()) {
    exit(0);
  }
}