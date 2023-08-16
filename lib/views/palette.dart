import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/tools/platformtools.dart';
import 'package:gooftuber_editor/views/editor.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';

class PaletteEditor extends StatefulWidget {
  const PaletteEditor({super.key});

  @override
  State<PaletteEditor> createState() => _PaletteEditorState();
}

class _PaletteEditorState extends State<PaletteEditor> {
  // responsive two column layout with list and detail

  // selected color
  int _selectedColor = -1;

  bool dragging = false;

  // list of colors
  Widget paletteList(bool big) {
    final GlobalKey key = GlobalKey();

    var view = SizedBox(
      key: key,
      width: big ? 350 : null,
      child: DropTarget(
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
          handleImportPaletteDrop(context, details, setState);
          setState(() {
            dragging = false;
          });
        },
        child: Stack(
          children: [
            ListView(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: colorPalettes.length,
                  itemBuilder: (context, index) {
                    final color = colorPalettes[index];
                    return ListTile(
                      title: Text(color.name),
                      subtitle: previewsVisible.value
                          ? SizedBox(
                              child: Row(
                                children: [
                                  Image.memory(
                                    Uint8List.fromList(
                                        colorPalettes[index].saveAsPng()),
                                    gaplessPlayback: true,
                                    scale: 5,
                                  ),
                                ],
                              ),
                            )
                          : null,
                      selected: index == _selectedColor,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            colorPalettes.removeAt(index);
                            selected = [];
                            if (_selectedColor == index) {
                              _selectedColor = -1;
                            }
                            saveColorPalettes();
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          selected = [];
                          _selectedColor = index;
                        });
                      },
                    );
                  },
                ),
                const Divider(height: 1, thickness: .2),
                ListTile(
                    title: const Text('Add a Palette'),
                    leading: const Icon(Icons.add),
                    onTap: () {
                      setState(() {
                        colorPalettes.add(painter.ColorPalette(
                            'New Palette', [Colors.white]));
                        _selectedColor = colorPalettes.length - 1;
                      });
                    }),
                ListTile(
                    title: const Text('Import a Palette'),
                    leading: const Icon(Icons.import_export_rounded),
                    onTap: () async {
                      await importPalette(context);
                      setState(() {});
                    }),
              ],
            ),
            if (dragging)
              Container(
                height: double.infinity,
                width: double.infinity,
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
              )
          ],
        ),
      ),
    );
    if (big) {
      return SizedBox(
        width: 350,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Palette Editor'),
            actions: [help()],
          ),
          body: view,
        ),
      );
    } else {
      return view;
    }
  }

  Color getContrastingColor(Color color) {
    var yiq =
        ((color.red * 299) + (color.green * 587) + (color.blue * 114)) / 1000;
    return (yiq >= 128) ? Colors.black : Colors.white;
  }

  var selected = [];

  // detail of selected color
  Widget paletteDetails(bool big) {
    // calculate cross axis count where each color is 50 pixels wide
    final crossAxisCount = (MediaQuery.of(context).size.width / 200).floor();
    if (_selectedColor == -1) {
      return const Center(
        child: Text('No Palette selected'),
      );
    }
    // check if selected color is valid
    if (_selectedColor >= colorPalettes.length) {
      return const Center(
        child: Text('Invalid Palette selected'),
      );
    }

    // grid view of colors
    var gridView = Padding(
      padding: const EdgeInsets.all(8.0),
      child: StatefulBuilder(builder: (context, setState) {
        return ReorderableGridView.builder(
          shrinkWrap: true,
          itemCount: colorPalettes[_selectedColor].colors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemBuilder: (context, index) {
            final color = colorPalettes[_selectedColor].colors[index];
            return Padding(
              key: ValueKey(index),
              padding: const EdgeInsets.all(4),
              child: colorCard(color, index, context, setState),
            );
          },
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              final color =
                  colorPalettes[_selectedColor].colors.removeAt(oldIndex);
              colorPalettes[_selectedColor].colors.insert(newIndex, color);
              saveColorPalettes();
            });
          },
        );
      }),
    );

    var view = Scaffold(
        floatingActionButton: selected.isNotEmpty
            ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    selected.sort();
                    selected = selected.reversed.toList();
                    for (var index in selected) {
                      colorPalettes[_selectedColor].colors.removeAt(index);
                    }
                    selected = [];
                    saveColorPalettes();
                  });
                },
                child: const Icon(Icons.delete),
              )
            : null,
        appBar: AppBar(
          leading: Container(),
          leadingWidth: 0,
          title: TextField(
            decoration: const InputDecoration(
              labelText: 'Palette Name',
            ),
            onSubmitted: (value) {
              setState(() {
                colorPalettes[_selectedColor].name = value;
                saveColorPalettes();
              });
            },
            controller:
                TextEditingController(text: colorPalettes[_selectedColor].name),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                var color = Colors.white;
                // show color picker
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Pick a Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          portraitOnly: true,
                          pickerAreaHeightPercent: 0.5,
                          labelTypes: const [ColorLabelType.rgb],
                          enableAlpha: true,
                          pickerColor: color,
                          onColorChanged: (value) {
                            color = value;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              colorPalettes[_selectedColor].colors.add(color);
                            });
                            saveColorPalettes();
                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              onPressed: () {
                setState(() {
                  colorPalettes.removeAt(_selectedColor);
                  _selectedColor = -1;
                });
                saveColorPalettes();
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: 'export',
                    child: Text('Export as JSON'),
                  ),
                  const PopupMenuItem(
                    value: 'export_png',
                    child: Text('Export as PNG'),
                  ),
                ];
              },
              onSelected: (value) {
                if (value == 'export') {
                  exportString(
                      context,
                      jsonEncode(colorPalettes[_selectedColor].toJson()),
                      "${colorPalettes[_selectedColor].name}.json",
                      ["json"]);
                } else if (value == 'export_png') {
                  exportBytes(
                      context,
                      Uint8List.fromList(
                          colorPalettes[_selectedColor].saveAsPng(scale: 1)),
                      "${colorPalettes[_selectedColor].name}.png",
                      ["png"]);
                }
              },
            )
          ],
        ),
        body: Column(
          children: [
            const Divider(height: 1, thickness: .2),
            Expanded(
              child: gridView,
            ),
          ],
        ));

    return view;
  }

  Widget colorCard(Color color, int index, BuildContext context,
      void Function(void Function()) setStateContainer) {
    bool hovered = false;
    return StatefulBuilder(builder: (context, setState) {
      return Card(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        color: color,
        child: InkWell(
          hoverColor: Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          onTap: () {
            this.setState(() {
              if (selected.contains(index)) {
                selected.remove(index);
              } else {
                selected.add(index);
              }
            });
          },
          child: MouseRegion(
            onEnter: (event) => setState(() => hovered = true),
            onExit: (event) => setState(() => hovered = false),
            child: Stack(
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: isPlatformMobile() ||
                              selected.contains(index) ||
                              hovered
                          ? 1
                          : 0,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Checkbox(
                            value: selected.contains(index),
                            onChanged: (value) {
                              this.setState(() {
                                if (value == null) return;
                                if (value) {
                                  selected.add(index);
                                } else {
                                  selected.remove(index);
                                }
                              });
                            }),
                      ),
                    )
                  ])
                ]),
                Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        color: getContrastingColor(color),
                        onPressed: () {
                          setStateContainer(() {
                            selected = [];
                            colorPalettes[_selectedColor]
                                .colors
                                .removeAt(index);
                          });
                          saveColorPalettes();
                        },
                      ),
                      IconButton(
                        color: getContrastingColor(color),
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          var color =
                              colorPalettes[_selectedColor].colors[index];
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Edit Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    portraitOnly: true,
                                    pickerAreaHeightPercent: 0.5,
                                    labelTypes: const [ColorLabelType.rgb],
                                    enableAlpha: true,
                                    pickerColor: color,
                                    onColorChanged: (value) {
                                      color = value;
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      setStateContainer(() {
                                        colorPalettes[_selectedColor]
                                            .colors[index] = color;
                                      });
                                      saveColorPalettes();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Done'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  )
                ]),
              ],
            ),
          ),
        ),
      );
    });
  }

  // responsive one column layout with list and detail
  Widget twoPaneLayout(bool big) {
    return Row(
      children: [
        paletteList(big),
        const VerticalDivider(width: 1, thickness: .2),
        Expanded(
          child: paletteDetails(big),
        ),
      ],
    );
  }

  // responsive one column layout with list and detail
  Widget onePaneLayout(bool big) {
    return paletteList(big);
  }

  @override
  Widget build(BuildContext context) {
    // get width of screen
    final width = MediaQuery.of(context).size.width;

    var big = width > 700;

    var mainLayout = onePaneLayout(big);

    // if width is greater than 700, use two column layout
    if (big) {
      mainLayout = twoPaneLayout(big);
    }

    if (!big && _selectedColor != -1) {
      mainLayout = paletteDetails(big);
    }

    return Scaffold(
      appBar: big
          ? null
          : AppBar(
              title: _selectedColor == -1
                  ? const Text('Palette Editor')
                  : Text(
                      'Palette Editor - ${colorPalettes[_selectedColor].name}'),
              leading: _selectedColor == -1
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedColor = -1;
                        });
                        saveColorPalettes();
                      },
                    ),
              actions: [
                if (_selectedColor == -1) help(),
              ],
            ),
      body: mainLayout,
    );
  }

  PopupMenuButton<String> help() {
    return PopupMenuButton(
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'help',
            child: Text('Help'),
          ),
        ];
      },
      onSelected: (value) async {
        if (value == 'help') {
          await launchUrl(Uri.parse(
              'https://docs.awesomesauce.software/gooftuber/editor/palette.html'));
        }
      },
    );
  }
}
