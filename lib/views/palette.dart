import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/jsonexport.dart';
import 'package:gooftuber_editor/views/painter.dart';

class PaletteEditor extends StatefulWidget {
  const PaletteEditor({super.key});

  @override
  State<PaletteEditor> createState() => _PaletteEditorState();
}

class _PaletteEditorState extends State<PaletteEditor> {
  // responsive two column layout with list and detail

  // selected color
  int _selectedColor = -1;

  // list of colors
  Widget paletteList(bool big) {
    var view = SizedBox(
      width: big ? 350 : null,
      child: ListView(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: colorPalettes.length,
            itemBuilder: (context, index) {
              final color = colorPalettes[index];
              return ListTile(
                title: Text(color.name),
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
                  colorPalettes
                      .add(ColorPalette('New Palette', [Colors.white]));
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
    );
    if (big) {
      return SizedBox(
        width: 350,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Palette Editor'),
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
      child: GridView.builder(
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
            padding: const EdgeInsets.all(4),
            child: Card(
              color: color,
              child: Stack(
                children: [
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Checkbox(value: selected.contains(index), onChanged: (value) {
                          setState(() {
                            if (value==null) return;
                            if (value) {
                              selected.add(index);
                            } else {
                              selected.remove(index);
                            }
                          });
                        }),
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
                            setState(() {
                              colorPalettes[_selectedColor]
                                  .colors
                                  .removeAt(index);
                            });
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
                                        setState(() {
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
          );
        },
      ),
    );

    var view = Scaffold(
      floatingActionButton: selected.isNotEmpty? FloatingActionButton(
        onPressed: () {
          setState(() {
            selected.sort();
            selected = selected.reversed.toList();
            for (var index in selected) {
              colorPalettes[_selectedColor].colors.removeAt(index);
            }
            selected = [];
          });
        },
        child: const Icon(Icons.delete),
      ):null,
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
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  colorPalettes[_selectedColor].colors.add(Colors.white);
                });
                saveColorPalettes();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
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
                    child: Text('Export'),
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
                }
              },
            )
          ],
        ),
      body: Column(children: [
        
        const Divider(height: 1, thickness: .2),
        Expanded(
          child: gridView,
        ),
      ],
    ));

    return view;
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

    // if width is greater than 600, use two column layout
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
            ),
      body: mainLayout,
    );
  }
}
