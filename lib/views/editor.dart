import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/apitools.dart';
import 'package:gooftuber_editor/views/dialogs.dart';
import 'package:gooftuber_editor/views/editor/dialogs.dart';
import 'package:gooftuber_editor/views/editor/utils.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/tools/sprite_tools.dart';
import 'package:gooftuber_editor/views/view_sprites.dart';

class Editor extends StatefulWidget {
  const Editor({super.key, required this.title});
  final String title;

  @override
  State<Editor> createState() => _EditorPageState();
}

var navRailState = DrawerState.pinned;
var picturesState = DrawerState.pinned;

class _EditorPageState extends State<Editor>
    with SingleTickerProviderStateMixin {
  void setupKeyboardShortcuts() {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      if (event.runtimeType != RawKeyDownEvent) return;

      if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyZ)) {
        undo(currentPage);
        undoRedo.value++;
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyY)) {
        redo(currentPage);
        undoRedo.value++;
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
          picturesState = toggle(picturesState, DrawerTypes.layers);
        });
      } else if (event.isControlPressed &&
          event.isKeyPressed(LogicalKeyboardKey.keyM)) {
        // menu
        setState(() {
          navRailState = toggle(navRailState, DrawerTypes.navRail);
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

  DrawerState toggle(DrawerState state, DrawerTypes types) {
    if (types == DrawerTypes.navRail) {
      if (state == DrawerState.pinned) {
        return DrawerState.modal;
      } else if (state == DrawerState.modal) {
        scaffold.currentState?.openDrawer();
      } else {
        return DrawerState.pinned;
      }
    } else {
      if (state == DrawerState.pinned) {
        return DrawerState.modal;
      } else if (state == DrawerState.modal) {
        scaffold.currentState?.openEndDrawer();
      } else {
        return DrawerState.pinned;
      }
    }
    return state;
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

  var previewsVisible = true;

  var currentPage = Pages.editor;

  Widget navRail() {
    return FutureBuilder(
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
              if (apiUp.data ?? false)
                const NavigationRailDestination(
                  icon: Icon(Icons.cloud_upload_rounded),
                  label: Text('Sync'),
                ),
              if (navRailState != DrawerState.pinned)
                const NavigationRailDestination(
                  icon: Icon(Icons.push_pin_rounded),
                  label: Text('Pin'),
                ),
              if (navRailState == DrawerState.pinned)
                const NavigationRailDestination(
                  icon: Icon(Icons.push_pin_rounded),
                  label: Text('Unpin'),
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
                List<painter.Image> newSprites = await importFile(context);
                setState(() {
                  sprites = newSprites;
                });
              } else if (index == 3) {
                String json = exportJson(sprites);
                exportFile(context, json);
              } else if (index == 4) {
                showCodeDialog(context).then((value) async {
                  if (value != null) {
                    var result = await submitAvatar(exportJson(sprites), value);
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
              } else if (index == 5) {
                if (navRailState == DrawerState.pinned) {
                  scaffold.currentState?.openDrawer();
                  setState(() {
                    navRailState = DrawerState.modal;
                  });
                } else {
                  scaffold.currentState?.closeDrawer();
                  setState(() {
                    navRailState = DrawerState.pinned;
                  });
                }
              }
            },
          );
        });
  }

  GlobalKey<ScaffoldState> scaffold = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffold,
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: bottomBar(),
      ),
      endDrawer: Drawer(child: drawer(context)),
      drawer: Drawer(
        width: 100,
        child: navRail(),
      ),
      body: SafeArea(
          child: Row(
        children: [
          if (navRailState == DrawerState.pinned) navRail(),
          if (navRailState == DrawerState.pinned)
            const VerticalDivider(width: 1),
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
          if (picturesState == DrawerState.pinned &&
              currentPage == Pages.editor)
            const VerticalDivider(width: 1),
          if (picturesState == DrawerState.pinned &&
              currentPage == Pages.editor)
            drawer(context)
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
                icon: navRailState == DrawerState.pinned
                    ? const Icon(Icons.menu_rounded)
                    : const Icon(Icons.menu_open_rounded),
                onPressed: () {
                  setState(() {
                    navRailState = toggle(navRailState, DrawerTypes.navRail);
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
              IconButton(
                  tooltip: 'Save Project',
                  icon: const Icon(Icons.save_rounded),
                  onPressed: isEnabled() ? () => saveProject() : null),
              IconButton(
                tooltip: 'Toggle Theme',
                icon: appTheme.value != 2
                    ? appTheme.value == 0
                        ? const Icon(Icons.dark_mode_rounded)
                        : const Icon(Icons.light_mode_rounded)
                    : const Icon(Icons.auto_awesome_rounded),
                onPressed: () {
                  setState(() {
                    int value = appTheme.value + 1;
                    if (value > 2) {
                      value = 0;
                    }
                    appTheme.value = value;
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
                  icon: picturesState == DrawerState.pinned
                      ? const Icon(Icons.layers_rounded)
                      : const Icon(Icons.layers_clear_rounded),
                  onPressed: () {
                    setState(() {
                      picturesState = toggle(picturesState, DrawerTypes.layers);
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
                          leading: picturesState != DrawerState.pinned
                              ? IconButton(
                                  icon: const Icon(Icons.push_pin_rounded),
                                  onPressed: () {
                                    scaffold.currentState?.closeEndDrawer();
                                    setState(() {
                                      picturesState = DrawerState.pinned;
                                    });
                                  },
                                )
                              : null,
                          title: const Text("Frames and Color"),
                          centerTitle: false,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () {
                                // dialog for sprite name
                                showSpriteNameDialog(context, nameController,
                                    wxhController, setState);
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
                              painter.colorSet = colors[i];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colors[i],
                              border: (painter.colorSet == colors[i])
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
}
