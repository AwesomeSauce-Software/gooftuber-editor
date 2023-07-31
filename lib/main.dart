import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelart/painter.dart' as painter;
import 'package:pixelart/tools/platformtools.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';

// TODO: Make names unique
// TODO: When copying, make sure to copy the name too and append (copy) to it
// TODO: Add primary toggle when adding/editing which is the default frame
// TODO: Add expression toggle which is used for expressions, adds primary frame as background and allows you to draw on top of it
// TODO: Add json exporting of all frames
// TODO: Add json importing of all frames
// TODO: Add preview of all frames

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  runApp(const MyApp());

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    // set min size
    windowManager.setMinimumSize(const Size(960, 600));
    // set title
    windowManager.setTitle('Gooftuber Avatar Editor');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
              themeMode: mode == 0 ? ThemeMode.light : ThemeMode.dark,
              debugShowCheckedModeBanner: false,
              home: const MyHomePage(title: 'Gooftuber Avatar Editor'),
            );
          }),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // refresh updater every sec
  @override
  void initState() {
    super.initState();
    wxhController.text = '128';
    refresh();

    // keyboard shortcuts
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      if (event.runtimeType != RawKeyDownEvent) return;

      if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyZ)) {
        undo();
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyY)) {
        redo();
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyS)) {
        // save
        saveFile(event.isShiftPressed);
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyL)) {
        // layers
        setState(() {
          picturesVisible = !picturesVisible;
        });
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyM)) {
        // menu
        setState(() {
          navRailVisible = !navRailVisible;
        });
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyA)) {
        // add
        showSpriteNameDialog(context);
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyT)) {
        // toggle theme
        setState(() {
          appTheme.value = appTheme.value == 0 ? 1 : 0;
        });
      }
    });
  }

  void refresh() {
    Future.delayed(const Duration(seconds: 1), () {
      // clear redo and undo above 10
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
      updater.value = toUpdate;
      refresh();
    });
  }

  bool isEnabled() {
    return sprites.isNotEmpty && imageSelected.value >= 0;
  }

  var nameController = TextEditingController();
  var wxhController = TextEditingController();

  var navRailVisible = true;
  var picturesVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: bottomBar(),
      ),
      body: SafeArea(
          child: Row(
        children: [
          if (navRailVisible)
            NavigationRail(
              labelType: NavigationRailLabelType.all,
              // color selected chip
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.edit),
                  label: Text('Editor'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_album),
                  label: Text('View'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder),
                  label: Text('Import'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.save_alt),
                  label: Text('Export'),
                ),
              ],
              selectedIndex: 0,
              useIndicator: true,
              onDestinationSelected: (int index) async {
                if (index == 0) {
                  // editor
                } else if (index == 1) {
                  // view
                } else if (index == 2) {
                  // import
                } else if (index == 3) {}
              },
            ),
          if (navRailVisible) const VerticalDivider(width: 1),
          Expanded(
              child: ValueListenableBuilder(
                  valueListenable: imageSelected,
                  builder: (context, spriteSelected, _) {
                    if (sprites.isEmpty) {
                      return const Center(
                        child: Text('No images found'),
                      );
                    }
                    if (spriteSelected < 0) {
                      spriteSelected = 0;
                    }
                    // build pixel art editor
                    return const painter.Painter();
                  })),
          if (picturesVisible) const VerticalDivider(width: 1),
          if (picturesVisible) drawer(context)
        ],
      )),
    );
  }

  Widget bottomBar() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: navRailVisible
                    ? const Icon(Icons.menu)
                    : const Icon(Icons.menu_open),
                onPressed: () {
                  setState(() {
                    navRailVisible = !navRailVisible;
                  });
                },
              ),
              ValueListenableBuilder(
                  valueListenable: spriteBefore,
                  builder: (_, sprite, ___) {
                    return IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: (sprite.isNotEmpty) ? undo : null,
                    );
                  }),
              ValueListenableBuilder(
                  valueListenable: spriteRedo,
                  builder: (_, sprite, ___) {
                    return IconButton(
                      icon: const Icon(Icons.redo),
                      onPressed: (sprite.isNotEmpty) ? redo : null,
                    );
                  }),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                  valueListenable: updater,
                  builder: (_, __, ___) {
                    if (lastSaved == 0) {
                      return const Text('Not saved yet');
                    }
                    // calculate timestamp
                    var time =
                        DateTime.now().millisecondsSinceEpoch - lastSaved;
                    var seconds = (time / 1000).floor();
                    var minutes = (seconds / 60).floor();
                    return Text('Last saved: $minutes minutes ago');
                  }),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'WxH',
                  ),
                  keyboardType: TextInputType.number,
                  // only allow numbers
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(3),
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  enabled: sprites.isEmpty,
                  textAlign: TextAlign.center,
                  controller: wxhController,
                  onSubmitted: (String value) {},
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: isEnabled() ? () => saveFile(false) : null),
              IconButton(
                icon: appTheme.value == 0
                    ? const Icon(Icons.dark_mode)
                    : const Icon(Icons.light_mode),
                onPressed: () {
                  setState(() {
                    appTheme.value = appTheme.value == 0 ? 1 : 0;
                  });
                },
              ),
              IconButton(
                icon: picturesVisible
                    ? const Icon(Icons.layers)
                    : const Icon(Icons.layers_clear),
                onPressed: () {
                  setState(() {
                    picturesVisible = !picturesVisible;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  redo() {
    // redo by using spriteRedo[0]
    setState(() {
      spriteBefore.value.add(sprites[imageSelected.value]);
      sprites[imageSelected.value] = spriteRedo.value[0];
      spriteRedo.value.removeAt(0);
      updater.value++;
    });
  }

  undo() {
    // undo by using spriteBefore[0]
    setState(() {
      spriteRedo.value.add(sprites[imageSelected.value]);
      sprites[imageSelected.value] = spriteBefore.value[0];
      spriteBefore.value.removeAt(0);
      updater.value++;
    });
  }

  void saveFile(bool overidePath) async {
    // save as dialog
    if (sprites.isEmpty) {
      return;
    }
    if (imageSelected.value < 0) {
      imageSelected.value = 0;
    }
    if (!overidePath && sprites[imageSelected.value].path != '') {
      List<int> bytes = sprites[imageSelected.value].saveAsPng();
      await File(sprites[imageSelected.value].path).writeAsBytes(bytes);
      lastSaved = DateTime.now().millisecondsSinceEpoch;
      updater.value++;
      return;
    }
    String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save avatar Frame',
        allowedExtensions: ['png'],
        fileName: '${sprites[0].name}.png');
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

  var dragging = false;

  Future<void> handleFileDrop(DropDoneDetails details) async {
    for (var file in details.files) {
      if (!file.name.endsWith('.png')) {
        continue;
      }
      var bytes = await file.readAsBytes();
      var pixels = painter.loadFromPng(bytes);
      var image = painter.Image(file.name.replaceAll('.png', ''),
          pixels[0].length, pixels.length, pixels);
      setState(() {
        sprites.add(image);
      });
    }
  }

  Widget drawer(BuildContext context) {
    final GlobalKey key = GlobalKey();
    Future<Size> getSizes() async {
      return await Future.delayed(Duration.zero, () {
        final RenderBox? renderBox =
            key.currentContext?.findRenderObject() as RenderBox?;
        final size = renderBox?.size;
        return size!;
      });
    }

    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          dragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          dragging = false;
        });
      },
      onDragDone: (details) {
        handleFileDrop(details);
        setState(() {
          dragging = false;
        });
      },
      child: Stack(
        children: [
          Drawer(
              key: key,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(0)),
              ),
              child: ValueListenableBuilder(
                  valueListenable: imageSelected,
                  builder: (context, spriteSelected, _) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text("Frames"),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              // dialog for sprite name
                              showSpriteNameDialog(context);
                            },
                          ),
                        ],
                      ),
                      body:
                          ListView(padding: EdgeInsets.zero, children: <Widget>[
                        for (var i = 0; i < sprites.length; i++)
                          ListTile(
                            leading: i == imageSelected.value
                                ? const Icon(Icons.radio_button_checked)
                                : const Icon(Icons.radio_button_off),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 0,
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 1,
                                  child: Text('Copy'),
                                ),
                                PopupMenuItem(
                                  value: 2,
                                  child: Text('Delete'),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 0:
                                    setState(() {
                                      // change name
                                      nameController.text = sprites[i].name;
                                      editNameDialog(context, i);
                                    });
                                    break;
                                  case 1:
                                    setState(() {
                                      sprites.add(sprites[i]);
                                    });
                                    break;
                                  case 2:
                                    setState(() {
                                      sprites.removeAt(i);
                                      if (imageSelected.value >=
                                          sprites.length) {
                                        imageSelected.value =
                                            sprites.length - 1;
                                      }
                                      if (sprites.isEmpty) {
                                        nameController.text = '';
                                      }
                                    });
                                    break;
                                }
                              },
                            ),
                            /*Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        setState(() {
                                          // change name
                                          nameController.text = sprites[i].name;
                                          editNameDialog(context, i);
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        setState(() {
                                          sprites.add(sprites[i]);
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          sprites.removeAt(i);
                                          if (imageSelected.value >=
                                              sprites.length) {
                                            imageSelected.value =
                                                sprites.length - 1;
                                          }
                                          if (sprites.isEmpty) {
                                            nameController.text = '';
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),*/
                            title: Text(sprites[i].name),
                            onTap: () {
                              imageSelected.value = i;
                            },
                          ),
                      ]),
                    );
                  })),
          if (dragging)
            FutureBuilder<Size>(
              future: getSizes(),
              builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    height: snapshot.data!.height,
                    width: snapshot.data!.width,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.file_upload),
                          Text('Release to import')
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            )
        ],
      ),
    );
  }

  void editNameDialog(BuildContext context, int i) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Sprite Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Every Avatar needs a 'talking' and 'nontalking' sprite.\nExpression sprites are optional and can be called anything."),
                Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
                    child: Autocomplete(
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextField(
                          decoration: const InputDecoration(
                            label: Text('Sprite Name'),
                            border: OutlineInputBorder(),
                            hintText: 'Enter Frame Name',
                          ),
                          textAlign: TextAlign.center,
                          controller: nameController,
                          focusNode: focusNode,
                          onSubmitted: (String value) {
                            onFieldSubmitted();

                            // add sprite
                            setState(() {
                              sprites[i].name = nameController.text;
                            });

                            Navigator.pop(context);
                          },
                        );
                      },
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return ['talking', 'nontalking', 'Expression_'];
                      },
                      onSelected: (String selection) {
                        debugPrint('You just selected $selection');
                      },
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // add sprite
                  setState(() {
                    sprites[i].name = nameController.text;
                  });
                },
                child: const Text('Change'),
              ),
            ],
          );
        });
  }

  void showSpriteNameDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Sprite Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Every Avatar needs a 'talking' and 'nontalking' sprite.\nExpression sprites are optional and can be called anything."),
                Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
                    child: Autocomplete(
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextField(
                          decoration: const InputDecoration(
                            label: Text('Sprite Name'),
                            border: OutlineInputBorder(),
                            hintText: 'Enter Frame Name',
                          ),
                          textAlign: TextAlign.center,
                          controller: nameController,
                          focusNode: focusNode,
                          onSubmitted: (String value) {
                            onFieldSubmitted();

                            // add sprite
                            setState(() {
                              sprites.add(painter.Image(
                                  nameController.text,
                                  int.parse(wxhController.text),
                                  int.parse(wxhController.text), [
                                for (var i = 0;
                                    i < int.parse(wxhController.text);
                                    i++)
                                  [
                                    for (var j = 0;
                                        j < int.parse(wxhController.text);
                                        j++)
                                      painter.Pixel(Colors.transparent)
                                  ]
                              ]));
                            });

                            Navigator.pop(context);
                          },
                        );
                      },
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return ['talking', 'nontalking', 'Expression_'];
                      },
                      onSelected: (String selection) {
                        debugPrint('You just selected $selection');
                      },
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // add sprite
                  setState(() {
                    sprites.add(painter.Image(
                        nameController.text,
                        int.parse(wxhController.text),
                        int.parse(wxhController.text), [
                      for (var i = 0; i < int.parse(wxhController.text); i++)
                        [
                          for (var j = 0;
                              j < int.parse(wxhController.text);
                              j++)
                            painter.Pixel(Colors.transparent)
                        ]
                    ]));
                  });
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
  }
}

var appTheme = ValueNotifier(0);

// timestamp of when the last save was made
var lastSaved = 0;
var updater = ValueNotifier(0);
List<painter.Image> sprites = [];

ValueNotifier<List<painter.Image>> spriteBefore = ValueNotifier([]);
ValueNotifier<List<painter.Image>> spriteRedo = ValueNotifier([]);
  ValueNotifier<int> imageSelected = ValueNotifier(0);
