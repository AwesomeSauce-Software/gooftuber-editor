import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pixelart/dialogs.dart';
import 'package:pixelart/painter.dart' as painter;
import 'package:pixelart/tools/jsonexport.dart';
import 'package:pixelart/tools/platformtools.dart';
import 'package:pixelart/tools/sprite_tools.dart';
import 'package:pixelart/view_sprites.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';

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

enum Pages { editor, view }

class Gooftuber extends StatelessWidget {
  const Gooftuber({super.key});

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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
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
        if (currentPage != Pages.editor) return;
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
      if (undoRedo.value > 100) {
        undoRedo.value = 0;
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
  var previewsVisible = true;

  var currentPage = Pages.editor;

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
              // groupAlignment: 0,
              labelType: NavigationRailLabelType.all,
              // color selected chip
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.edit_rounded),
                  label: Text('Editor'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_album_rounded),
                  label: Text('View'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_rounded),
                  label: Text('Import'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.save_alt_rounded),
                  label: Text('Export'),
                ),
              ],
              selectedIndex: currentPage.index,
              useIndicator: true,
              onDestinationSelected: (int index) async {
                if (index == 0) {
                  // editor
                  setState(() {
                    currentPage = Pages.editor;
                  });
                } else if (index == 1) {
                  // view
                  setState(() {
                    currentPage = Pages.view;
                  });
                } else if (index == 2) {
                  var newSprites = await importFile(context);
                  setState(() {
                    sprites = newSprites;
                  });
                } else if (index == 3) {
                  String json = exportJson(sprites);
                  exportFile(context, json);
                }
              },
            ),
          if (navRailVisible) const VerticalDivider(width: 1),
          if (currentPage == Pages.editor)
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
          if (currentPage == Pages.view) const Expanded(child: SpritePreview()),
          if (picturesVisible && currentPage == Pages.editor)
            const VerticalDivider(width: 1),
          if (picturesVisible && currentPage == Pages.editor) drawer(context)
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
                tooltip: 'Toggle Navigation Rail',
                icon: navRailVisible
                    ? const Icon(Icons.menu_rounded)
                    : const Icon(Icons.menu_open_rounded),
                onPressed: () {
                  setState(() {
                    navRailVisible = !navRailVisible;
                  });
                },
              ),
              if (currentPage == Pages.editor)
                ValueListenableBuilder(
                    valueListenable: spriteBefore,
                    builder: (_, sprite, ___) {
                      return IconButton(
                        tooltip: 'Undo',
                        icon: const Icon(Icons.undo_rounded),
                        onPressed: (sprite.isNotEmpty) ? undo : null,
                      );
                    }),
              if (currentPage == Pages.editor)
                ValueListenableBuilder(
                    valueListenable: spriteRedo,
                    builder: (_, sprite, ___) {
                      return IconButton(
                        tooltip: 'Redo',
                        icon: const Icon(Icons.redo_rounded),
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
              if (currentPage == Pages.editor)
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
              if (currentPage == Pages.editor)
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
              if (currentPage == Pages.editor)
                IconButton(
                    tooltip: 'Save image as PNG',
                    icon: const Icon(Icons.save_rounded),
                    onPressed: isEnabled() ? () => saveFile(false) : null),
              IconButton(
                tooltip: 'Toggle Theme',
                icon: appTheme.value == 0
                    ? const Icon(Icons.dark_mode_rounded)
                    : const Icon(Icons.light_mode_rounded),
                onPressed: () {
                  setState(() {
                    appTheme.value = appTheme.value == 0 ? 1 : 0;
                  });
                },
              ),
              if (currentPage == Pages.editor)
                IconButton(
                  tooltip: 'Toggle Previews',
                  icon: previewsVisible
                      ? const Icon(Icons.visibility_rounded)
                      : const Icon(Icons.visibility_off_rounded),
                  onPressed: () {
                    setState(() {
                      previewsVisible = !previewsVisible;
                    });
                  },
                ),
              if (currentPage == Pages.editor)
                IconButton(
                  tooltip: 'Toggle Frames',
                  icon: picturesVisible
                      ? const Icon(Icons.layers_rounded)
                      : const Icon(Icons.layers_clear_rounded),
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
    if (currentPage != Pages.editor) return;
    // redo by using spriteRedo[0]
    setState(() {
      spriteBefore.value.add(copyImage(sprites[imageSelected.value]));
      sprites[imageSelected.value] = spriteRedo.value[0];
      spriteRedo.value.removeAt(0);
      undoRedo.value++;
    });
  }

  undo() {
    if (currentPage != Pages.editor) return;
    // undo by using spriteBefore[0]
    setState(() {
      spriteRedo.value.add(copyImage(sprites[imageSelected.value]));
      sprites[imageSelected.value] = spriteBefore.value[0];
      spriteBefore.value.removeAt(0);
      undoRedo.value++;
    });
  }

  var dragging = false;

  Future<void> handleFileDrop(DropDoneDetails details) async {
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

    if (imageSelected.value < 0) {
      imageSelected.value = 0;
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
                    return DefaultTabController(
                      length: 2,
                      child: Scaffold(
                        bottomNavigationBar: const TabBar(
                          tabs: [
                            Tab(
                              icon: Icon(Icons.layers_rounded),
                            ),
                            Tab(
                              icon: Icon(Icons.color_lens_rounded),
                            ),
                          ],
                        ),
                        appBar: AppBar(
                          title: const Text("Frames and Color"),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () {
                                // dialog for sprite name
                                showSpriteNameDialog(context);
                              },
                            ),
                          ],
                        ),
                        body: TabBarView(
                          children: [
                            framesDrawer(context),
                            colorDrawer(),
                          ],
                        ),
                      ),
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
                          Icon(Icons.file_upload_rounded),
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

  Widget colorDrawer() {
    return StatefulBuilder(
      builder: (context, setState) => ListView(
        children: [
          ColorPicker(
          portraitOnly: true,
          pickerColor: painter.colorSet,
          onColorChanged: (color) {
            painter.colorSet = color;
          },
          pickerAreaHeightPercent: 1.0,
        ),
        if (colorHistory.value.isNotEmpty) const Divider(),
        // recent colors in grid
        ValueListenableBuilder(
          valueListenable: colorHistory,
          builder: (context, colors, _) {
            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              children: [
                for (var i = 0; i < colors.length; i++)
                  InkWell(
                    onTap: () {
                      setState(() {
                        painter.colorSet = colors[i];
                      });
                    },
                    child: Card(
                      color: colors[i],
                    ),
                  ),
              ],
            );
          }
        ),
        ],
      ),
    );
  }

  ListView framesDrawer(BuildContext context) {
    return ListView(padding: EdgeInsets.zero, children: <Widget>[
      for (var i = 0; i < sprites.length; i++)
        InkWell(
          onTap: () {
            imageSelected.value = i;
          },
          child: Container(
            color: i == imageSelected.value
                ? Theme.of(context).colorScheme.onInverseSurface
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: i == imageSelected.value
                      ? const Icon(Icons.radio_button_checked_rounded)
                      : const Icon(Icons.radio_button_off_rounded),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 0,
                        child: Text('Edit'),
                      ),
                      if (sprites[i].frameType == painter.FrameTypes.expression)
                        const PopupMenuItem(
                          value: 1,
                          child: Text('Copy'),
                        ),
                      const PopupMenuItem(
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
                            var frameType = sprites[i].frameType;
                            if (frameType != painter.FrameTypes.expression) {
                              frameType = painter.FrameTypes.expression;
                            }
                            var image = copyImage(sprites[i]);
                            image.name += ' copy';
                            sprites.add(image);
                          });
                          break;
                        case 2:
                          setState(() {
                            sprites.removeAt(i);
                            if (imageSelected.value >= sprites.length) {
                              imageSelected.value = sprites.length - 1;
                            }
                            if (sprites.isEmpty) {
                              nameController.text = '';
                            }
                          });
                          break;
                      }
                    },
                  ),
                  title:
                      Text(sprites[i].frameType == painter.FrameTypes.expression
                          ? sprites[i].name
                          : sprites[i].frameType == painter.FrameTypes.talking
                              ? 'Talking frame'
                              : 'Non-talking frame'),
                ),
                if (previewsVisible && !isImageEmpty(sprites[i]))
                  SizedBox(
                      width: 128,
                      height: 128,
                      child: Image.memory(
                          Uint8List.fromList(sprites[i].saveAsPng()),
                          gaplessPlayback: true)),
              ],
            ),
          ),
        )
    ]);
  }

  void editNameDialog(BuildContext context, int i) {
    painter.FrameTypes? frameType = sprites[i].frameType;

    bool expressionEnabled =
        sprites[i].frameType == painter.FrameTypes.expression;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Sprite Name'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Every Avatar needs a 'talking' and 'nontalking' sprite.\nExpression sprites are optional and can be called anything."),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        enabled: !expressionEnabled,
                        title: const Text("Talking Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.talking,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            if (expressionEnabled) {
                              showSnackbar(context,
                                  'You cannot change an optional Expression to a primary sprite!');
                              return;
                            }
                            setState(() {
                              frameType = value;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        enabled: !expressionEnabled,
                        title: const Text("Non-Talking Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.nontalking,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            if (expressionEnabled) {
                              showSnackbar(context,
                                  'You cannot change an optional Expression to a primary sprite!');
                              return;
                            }
                            setState(() {
                              frameType = value;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        enabled: expressionEnabled,
                        title: const Text("Expression Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.expression,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            if (!expressionEnabled) {
                              showSnackbar(context,
                                  'You cannot change an primary sprite to an optional Expression!');
                              return;
                            }
                            setState(() {
                              frameType = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (frameType == painter.FrameTypes.expression)
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
                                hintText: 'Enter Frame Type',
                              ),
                              textAlign: TextAlign.center,
                              controller: nameController,
                              focusNode: focusNode,
                              onSubmitted: (String value) {
                                onFieldSubmitted();

                                if (value == '' &&
                                    frameType ==
                                        painter.FrameTypes.expression) {
                                  // show error
                                  showSnackbar(context,
                                      'Sprite name cannot be empty. Please enter a name.');
                                  return;
                                }

                                // check if name is unique
                                for (var i = 0; i < sprites.length; i++) {
                                  if (sprites[i].name == value &&
                                      sprites[i].frameType ==
                                          painter.FrameTypes.expression) {
                                    // name is not unique
                                    // show error
                                    showSnackbar(context,
                                        'Sprite name must be unique. Please enter a different name.');
                                    return;
                                  }
                                }

                                // add sprite
                                setState(() {
                                  if (frameType ==
                                      painter.FrameTypes.expression) {
                                    sprites[i].name = nameController.text;
                                  } else {
                                    sprites[i].name = '';

                                    sprites[i].frameType = frameType!;
                                  }
                                });

                                nameController.text = '';

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
                  if (nameController.text == '' &&
                      frameType == painter.FrameTypes.expression) {
                    // show error
                    showSnackbar(context,
                        'Sprite name cannot be empty. Please enter a name.');
                    return;
                  }

                  // check if name is unique
                  for (var i = 0; i < sprites.length; i++) {
                    if (sprites[i].name == nameController.text &&
                        sprites[i].frameType == painter.FrameTypes.expression) {
                      // name is not unique
                      // show error
                      showSnackbar(context,
                          'Sprite name must be unique. Please enter a different name.');
                      return;
                    }
                  }

                  Navigator.pop(context);
                  // add sprite
                  setState(() {
                    if (frameType == painter.FrameTypes.expression) {
                      sprites[i].name = nameController.text;
                    } else {
                      sprites[i].name = '';

                      sprites[i].frameType = frameType!;
                    }
                  });
                  nameController.text = '';
                },
                child: const Text('Change'),
              ),
            ],
          );
        }).then((value) => setState(
          () => {},
        ));
  }

  void showSpriteNameDialog(BuildContext context) {
    painter.FrameTypes? frameType = painter.FrameTypes.talking;

    bool expressionEnabled = doesPrimarySpriteExist();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Sprite Name'),
            content: StatefulBuilder(
              builder: (context, StateSetter setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "Every Avatar needs a 'talking' and 'nontalking' sprite.\nExpression sprites are optional and can be called anything."),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text("Talking Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.talking,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            setState(() {
                              frameType = value;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("Non-Talking Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.nontalking,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            setState(() {
                              frameType = value;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        enabled: expressionEnabled,
                        title: const Text("Expression Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.expression,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            if (!expressionEnabled) {
                              showSnackbar(context,
                                  'You must create a talking and/or non-talking sprite before creating an expression sprite.');
                              return;
                            }
                            setState(() {
                              frameType = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  // radio buttons for sprite type
                  if (frameType == painter.FrameTypes.expression)
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
                                hintText: 'Enter Frame Type',
                              ),
                              textAlign: TextAlign.center,
                              controller: nameController,
                              focusNode: focusNode,
                              onSubmitted: (String value) {
                                onFieldSubmitted();

                                if (value == '' &&
                                    frameType ==
                                        painter.FrameTypes.expression) {
                                  // show error
                                  showSnackbar(context,
                                      'Sprite name cannot be empty. Please enter a name.');
                                  return;
                                }

                                // check if name is unique
                                for (var i = 0; i < sprites.length; i++) {
                                  if (sprites[i].name == value &&
                                      sprites[i].frameType ==
                                          painter.FrameTypes.expression) {
                                    // name is not unique
                                    // show error
                                    showSnackbar(context,
                                        'Sprite name must be unique. Please enter a different name.');
                                    return;
                                  }
                                }

                                // add sprite
                                setState(() {
                                  sprites.add(painter.Image(
                                      nameController.text,
                                      int.parse(wxhController.text),
                                      int.parse(wxhController.text),
                                      [
                                        for (var i = 0;
                                            i < int.parse(wxhController.text);
                                            i++)
                                          [
                                            for (var j = 0;
                                                j <
                                                    int.parse(
                                                        wxhController.text);
                                                j++)
                                              painter.Pixel(Colors.transparent)
                                          ]
                                      ],
                                      frameType!));
                                });

                                nameController.text = '';

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
                  if (nameController.text == '' &&
                      frameType == painter.FrameTypes.expression) {
                    // show error
                    showSnackbar(context,
                        'Sprite name cannot be empty. Please enter a name.');
                    return;
                  }

                  // check if name is unique
                  for (var i = 0; i < sprites.length; i++) {
                    if (sprites[i].name == nameController.text &&
                        frameType == painter.FrameTypes.expression) {
                      // name is not unique
                      // show error
                      showSnackbar(context,
                          'Sprite name must be unique. Please enter a different name.');
                      return;
                    }
                  }

                  Navigator.pop(context);
                  // add sprite
                  setState(() {
                    sprites.add(painter.Image(
                        nameController.text,
                        int.parse(wxhController.text),
                        int.parse(wxhController.text),
                        [
                          for (var i = 0;
                              i < int.parse(wxhController.text);
                              i++)
                            [
                              for (var j = 0;
                                  j < int.parse(wxhController.text);
                                  j++)
                                painter.Pixel(Colors.transparent)
                            ]
                        ],
                        frameType!));
                  });

                  nameController.text = '';
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
var undoRedo = ValueNotifier(0);
List<painter.Image> sprites = [];

ValueNotifier<List<painter.Image>> spriteBefore = ValueNotifier([]);
ValueNotifier<List<painter.Image>> spriteRedo = ValueNotifier([]);
ValueNotifier<int> imageSelected = ValueNotifier(0);
ValueNotifier<List<Color>> colorHistory = ValueNotifier([]);
