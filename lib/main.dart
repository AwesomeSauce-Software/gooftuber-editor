import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/views/editor.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:window_manager/window_manager.dart';

String currentTag = "v1.0.5";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    await windowManager.ensureInitialized();
  }
  runApp(const Gooftuber());

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    // set min size
    windowManager.setMinimumSize(const Size(960, 600));
    // set title
    windowManager.setTitle('Gooftuber Avatar Editor');
  }
}

enum Pages { editor, view, settings }

class Gooftuber extends StatelessWidget {
  const Gooftuber({super.key});

  @override
  Widget build(BuildContext context) {
    loadProject(context);
    loadSettings();
    return ValueListenableBuilder(
      valueListenable: appTheme,
      builder: (_, mode, __) {
        return DynamicColorBuilder(
          builder: ((lightDynamic, darkDynamic) {
            return MaterialApp(
              title: 'Gooftuber Avatar Editor',
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: lightDynamic,
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: darkDynamic,
                useMaterial3: true,
              ),
              themeMode: mode == 0 ? ThemeMode.light : mode == 1 ? ThemeMode.dark : ThemeMode.system,
              debugShowCheckedModeBanner: false,
              home: const Editor(title: 'Gooftuber Avatar Editor'),
            );
          }),
        );
      },
    );
  }
}

var appTheme = ValueNotifier(2);

// timestamp of when the last save was made
var lastSaved = 0;
var updater = ValueNotifier(0);
var undoRedo = ValueNotifier(0);
List<painter.Image> sprites = [];

ValueNotifier<List<painter.Image>> spriteBefore = ValueNotifier([]);
ValueNotifier<List<painter.Image>> spriteRedo = ValueNotifier([]);
ValueNotifier<int> imageSelected = ValueNotifier(0);
ValueNotifier<List<Color>> colorHistory = ValueNotifier([]);
ValueNotifier<bool> autoSave = ValueNotifier(false);

List<painter.ColorPalette> colorPalettes = [];