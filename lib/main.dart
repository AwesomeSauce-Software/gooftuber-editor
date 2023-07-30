
import 'dart:math';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelart/painter.dart' as painter;

void main() {
  runApp(const MyApp());
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
    refresh();
  }

  void refresh() {
    Future.delayed(const Duration(seconds: 1), () {
      var toUpdate = updater.value++;
      if (toUpdate > 100) {
        toUpdate = 0;
      }
      updater.value = toUpdate;
      refresh();
    });
  }

  bool isEnabled() {
    return sprites.isNotEmpty && imageSelected >= 0;
  }

  painter.Image createRandom() {
    var rng = Random();
    var width = rng.nextInt(128) + 1;
    var height = rng.nextInt(128) + 1;
    var pixels = List.generate(width, (i) => List.generate(height, (j) => painter.Pixel(Colors.white)));
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        pixels[i][j].color = Color.fromARGB(255, rng.nextInt(255), rng.nextInt(255), rng.nextInt(255));
      }
    }
    return painter.Image('Random Image', width, height, pixels);
  }

  var imageSelected = 0;

  Widget pixelArtEditor() {
    if (sprites.length == 0) {
      return const Center(
        child: Text('No images found'),
      );
    }
    if (imageSelected < 0) {
      imageSelected = 0;
    }
    // build pixel art editor
    return painter.Painter(image: sprites[imageSelected]);

  }

  var nameController = TextEditingController();
  var wxhController = TextEditingController();

  // pixel art editor
  @override
  Widget build(BuildContext context) {
    wxhController.text = '128';
    return Scaffold(
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: () {},
                  ),
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
                      textAlign: TextAlign.center,
                      controller: wxhController,
                      onSubmitted: (String value) {
                      },
                    ),
                  ),
                  IconButton(
                      icon: Icon(Icons.save),
                      onPressed: () {
                        lastSaved = DateTime.now().millisecondsSinceEpoch;
                        updater.value++;
                      }),
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
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                    sprites.add(painter.Image('New Image', int.parse(wxhController.text), int.parse(wxhController.text), [
                      for (var i = 0; i < int.parse(wxhController.text); i++)
                        [for (var j = 0; j < int.parse(wxhController.text); j++) painter.Pixel(Colors.transparent)]
                    ]));
                  });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          // edit text as title,
          title: Autocomplete(
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              return TextField(
                enabled: isEnabled(),
                decoration: const InputDecoration(
                  hintText: 'Enter Frame Name',
                ),
                textAlign: TextAlign.center,
                controller: nameController,
                focusNode: focusNode,
                onSubmitted: (String value) {
                  onFieldSubmitted();
                  // update name
                  setState(() {
                    sprites[imageSelected].name = value;
                  });
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
              print('You just selected $selection');
            },
          )),
      body: SafeArea(
          child: Row(
        children: [
          NavigationRail(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
            onDestinationSelected: (int index) {
              setState(() {
                // screenIndex = index;
              });
            },
          ),
          Expanded(child: pixelArtEditor()),
          Drawer(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(0)),
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            child: ListView(padding: EdgeInsets.zero, children: <Widget>[
              for (var i = 0; i < sprites.length; i++)
                ListTile(
                  leading: i == imageSelected
                      ? const Icon(Icons.radio_button_checked)
                      : const Icon(Icons.radio_button_off),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        sprites.removeAt(i);
                        if (imageSelected >= sprites.length) {
                          imageSelected = sprites.length - 1;
                        }
                        if (sprites.isEmpty) {
                          nameController.text = '';
                        }
                      });
                    },
                  ),
                  title: Text(sprites[i].name),
                  onTap: () {
                    setState(() {
                      imageSelected = i;
                    });
                  },
                ),
            ]),
          )
        ],
      )),
    );
  }
}

var appTheme = ValueNotifier(0);

// timestamp of when the last save was made
var lastSaved = 0;
var updater = ValueNotifier(0);
List<painter.Image> sprites = [];
