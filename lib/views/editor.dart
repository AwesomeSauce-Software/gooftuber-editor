import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/apitools.dart';
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:gooftuber_editor/views/dialogs.dart';
import 'package:gooftuber_editor/views/editor/dialogs.dart';
import 'package:gooftuber_editor/views/editor/utils.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/tools/sprite_tools.dart';
import 'package:gooftuber_editor/views/settings.dart';
import 'package:gooftuber_editor/views/view_sprites.dart';

class Editor extends StatefulWidget {
  const Editor({super.key, required this.title});
  final String title;

  @override
  State<Editor> createState() => _EditorPageState();
}

var navRailVisible = true;
var picturesVisible = true;

ValueNotifier<bool> previewsVisible = ValueNotifier(true);

class _EditorPageState extends State<Editor>
    with SingleTickerProviderStateMixin {
  void setupKeyboardShortcuts() {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      if (currentPage != Pages.editor) return;
      if (event.runtimeType != RawKeyDownEvent) return;

      if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyZ)) {
        undo(currentPage);
        undoRedo.value = ++undoRedo.value;
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyY)) {
        redo(currentPage);
        undoRedo.value = ++undoRedo.value;
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyE)) {
        // save
        if (currentPage != Pages.editor) return;
        saveFile(imageSelected.value);
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyS)) {
        // save
        if (currentPage != Pages.editor) return;
        saveProject();
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
        showSpriteNameDialog(context, nameController, wxhController, setState);
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyT)) {
        // toggle theme
        setState(() {
          appTheme.value = appTheme.value == 0 ? 1 : 0;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    wxhController.text = '128';
    refresh();

    // keyboard shortcuts
    setupKeyboardShortcuts();
  }

  var nameController = TextEditingController();
  var wxhController = TextEditingController();

  var currentPage = Pages.editor;
  var oldIndex = 0;

  int getNavRailIndex() {
    switch (currentPage) {
      case Pages.editor:
      case Pages.view:
        return currentPage.index;
      case Pages.settings:
        return 4;
      default:
        return 0;
    }
  }

  Widget getPage() {
    if (currentPage == Pages.editor) {
      return Container(
        key: const Key('editor'),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
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
                      return ValueListenableBuilder(
                          valueListenable: undoRedo,
                          builder: (context, _, __) {
                            return const painter.Painter();
                          });
                    })),
            if (picturesVisible && currentPage == Pages.editor)
              const VerticalDivider(width: 1),
            if (picturesVisible && currentPage == Pages.editor) drawer(context)
          ],
        ),
      );
    } else if (currentPage == Pages.view) {
      return Container(
          key: const Key('view'),
          color: Theme.of(context).colorScheme.surface,
          child: const SpritePreview());
    } else if (currentPage == Pages.settings) {
      return Container(
          key: const Key('settings'),
          color: Theme.of(context).colorScheme.surface,
          child: const SettingsView());
    }
    return const Expanded(child: Text('Error'));
  }

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
            FutureBuilder(
                future: isApiUp(),
                builder: (context, apiUp) {
                  return NavigationRail(
                    groupAlignment: 0,
                    labelType: NavigationRailLabelType.all,
                    // color selected chip
                    destinations: <NavigationRailDestination>[
                      const NavigationRailDestination(
                        icon: Icon(Icons.edit_rounded),
                        label: Text('Editor'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.photo_album_rounded),
                        label: Text('View'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.folder_rounded),
                        label: Text('Import'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.save_alt_rounded),
                        label: Text('Export'),
                      ),
                      const NavigationRailDestination(
                          icon: Icon(Icons.settings_rounded),
                          label: Text('Settings')),
                      if (apiUp.data ?? false)
                        const NavigationRailDestination(
                          icon: Icon(Icons.cloud_upload_rounded),
                          label: Text('Sync'),
                        ),
                    ],
                    selectedIndex: getNavRailIndex(),
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
                        List<painter.Image> newSprites =
                            await importFile(context);
                        setState(() {
                          sprites = newSprites;
                        });
                      } else if (index == 3) {
                        String json = exportJson(sprites);
                        exportFile(context, json);
                      } else if (index == 4) {
                        // settings
                        setState(() {
                          currentPage = Pages.settings;
                        });
                      } else if (index == 5) {
                        showCodeDialog(context).then((value) async {
                          if (value != null) {
                            var result =
                                await submitAvatar(exportJson(sprites), value);
                            if (!result) {
                              if (context.mounted) {
                                showSnackbar(context, 'Upload failed');
                              }
                            } else {
                              if (context.mounted) {
                                showSnackbar(context, 'Upload successful!');
                              }
                            }
                          }
                        });
                      }
                    },
                  );
                }),
          if (navRailVisible) const VerticalDivider(width: 1),
          Expanded(
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: getPage())),
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
                        onPressed: (sprite.isNotEmpty)
                            ? () {
                                undo(currentPage);
                                undoRedo.value++;
                              }
                            : null,
                      );
                    }),
              if (currentPage == Pages.editor)
                ValueListenableBuilder(
                    valueListenable: spriteRedo,
                    builder: (_, sprite, ___) {
                      return IconButton(
                        tooltip: 'Redo',
                        icon: const Icon(Icons.redo_rounded),
                        onPressed: (sprite.isNotEmpty)
                            ? () {
                                redo(currentPage);
                                undoRedo.value++;
                              }
                            : null,
                      );
                    }),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentPage == Pages.editor && autoSave.value)
                const Tooltip(
                    message: 'Auto save is enabled',
                    child: Icon(
                      Icons.autorenew_rounded,
                      color: Colors.green,
                    )),
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
              FutureBuilder(
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data == ClientState.upToDate) {
                      return const SizedBox.shrink();
                    } else if (snapshot.data == ClientState.outOfDate) {
                      return IconButton(
                        tooltip: 'Update available!',
                        icon: const Icon(Icons.update_rounded),
                        onPressed: () {
                          showUpdateDialog(context);
                        },
                      );
                    } else if (snapshot.data == ClientState.error) {
                      return IconButton(
                        tooltip: 'Error!',
                        icon: const Icon(Icons.warning_rounded),
                        onPressed: () {
                          showSnackbar(context, 'Failed to get latest version!',
                              color: Colors.redAccent);
                        },
                      );
                    } else {
                      return const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(),
                      );
                    }
                  } else {
                    return const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(),
                    );
                  }
                },
                future: isClientOutOfDate(),
              ),
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
              IconButton(
                  tooltip: 'Save Project',
                  icon: const Icon(Icons.save_rounded),
                  onPressed: isEnabled() ? () => saveProject() : null),
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

  var dragging = false;

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
        handleFileDrop(details, setState);
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
                      length: (colorPalettes.isNotEmpty) ? 3 : 2,
                      child: Scaffold(
                        bottomNavigationBar: TabBar(
                          tabs: [
                            const Tab(
                              icon: Icon(Icons.layers_rounded),
                            ),
                            const Tab(
                              icon: Icon(Icons.colorize_rounded),
                            ),
                            if (colorPalettes.isNotEmpty)
                              const Tab(
                                icon: Icon(Icons.palette_rounded),
                              ),
                          ],
                        ),
                        body: TabBarView(
                          children: [
                            framesDrawer(context),
                            colorDrawer(),
                            if (colorPalettes.isNotEmpty) colorPaletteDrawer(),
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

  int paletteSelected = -1;
  Widget colorPaletteDrawer() {
    return StatefulBuilder(builder: ((context, setState) {
      if (paletteSelected == -1) {
        // show a list of all palettes
        return ListView(
          children: [
            for (var i = 0; i < colorPalettes.length; i++)
              ListTile(
                title: Text(colorPalettes[i].name),
                subtitle: previewsVisible.value? SizedBox(
                    child: Row(
                      children: [
                        Image.memory(Uint8List.fromList(colorPalettes[i].saveAsPng()),
                                    gaplessPlayback: true, scale: 5,),
                      ],
                    ),
                  ) : null,
                onTap: () {
                  setState(() {
                    paletteSelected = i;
                  });
                  // this.setState(() {});
                },
              ),
          ],
        );
      } else {
        // show a grid of all colors in the palette
        return Scaffold(
          appBar: AppBar(
                  title: Text(colorPalettes[paletteSelected].name),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      setState(() {
                        paletteSelected = -1;
                      });
                    },
                  )),
          body: ListView(
            children: [
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                children: [
                  for (var i = 0;
                      i < colorPalettes[paletteSelected].colors.length;
                      i++)
                    InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            painter.colorSet.value =
                                colorPalettes[paletteSelected].colors[i];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: colorPalettes[paletteSelected].colors[i],
                            border: (painter.colorSet.value ==
                                    colorPalettes[paletteSelected].colors[i])
                                ? Border.all(
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                                    width: 3,
                                  )
                                : null,
                          ),
                        )),
                ],
              )
            ],
          ),
        );
      }
    }));
  }

  Widget colorDrawer() {
    return StatefulBuilder(
      builder: (context, setState) => ListView(
        children: [
          ValueListenableBuilder(
              valueListenable: painter.colorSet,
              builder: (context, colorSet, _) {
                return ColorPicker(
                  portraitOnly: true,
                  pickerColor: colorSet,
                  onColorChanged: (color) {
                    painter.colorSet.value = color;
                  },
                  pickerAreaHeightPercent: 1.0,
                );
              }),
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
                      Dismissible(
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          setState(() {
                            colors.removeAt(i);
                          });
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              painter.colorSet.value = colors[i];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colors[i],
                              border: (painter.colorSet.value == colors[i])
                                  ? Border.all(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5),
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
        ],
      ),
    );
  }

  Widget framesDrawer(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Frames"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              if (isPlatformWeb()) {
                var download = await showDownloadDialog(context);
                if (!download!) {
                  if (context.mounted) {
                    showSpriteNameDialog(
                        context, nameController, wxhController, setState);
                  }
                }
              } else {
                showSpriteNameDialog(
                    context, nameController, wxhController, setState);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: EdgeInsets.zero, children: <Widget>[
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
                        const PopupMenuItem(
                          value: 1,
                          child: Text('Copy'),
                        ),
                        const PopupMenuItem(
                          value: 2,
                          child: Text('Export as PNG'),
                        ),
                        const PopupMenuItem(
                          value: 3,
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 0:
                            setState(() {
                              // change name
                              nameController.text = sprites[i].name;
                              editNameDialog(
                                  context, i, nameController, setState);
                            });
                            break;
                          case 1:
                            setState(() {
                              List<painter.Image> copyList = List.from(sprites);
                              var frameType = copyList[i].frameType;
                              if (frameType != painter.FrameTypes.expression) {
                                frameType = painter.FrameTypes.expression;
                              }
                              var image = copyImage(copyList[i]);
                              image.name += ' copy';
                              image.frameType = frameType;
                              sprites.add(image);
                            });
                            break;
                          case 2:
                            saveFile(i);
                            break;
                          case 3:
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
                    title: Text(
                        sprites[i].frameType == painter.FrameTypes.expression
                            ? sprites[i].name
                            : sprites[i].frameType == painter.FrameTypes.talking
                                ? 'Talking frame'
                                : 'Non-talking frame'),
                  ),
                  if (previewsVisible.value && !isImageEmpty(sprites[i]))
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
      ]),
    );
  }
}
