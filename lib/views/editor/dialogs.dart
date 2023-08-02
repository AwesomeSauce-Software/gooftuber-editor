import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/sprite_tools.dart';
import 'package:gooftuber_editor/views/dialogs.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;

void editNameDialog(BuildContext context, int i, TextEditingController nameController, void Function(void Function()) setState) {
    painter.FrameTypes? frameType = sprites[i].frameType;

    bool talkingEnabled = doesTalkingExist();
    bool nontalkingEnabled = doesNonTalkingExist();

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
                        enabled: !talkingEnabled,
                        title: const Text("Talking Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.talking,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            if (talkingEnabled) {
                              showSnackbar(
                                  context, 'A talking sprite already exists!');
                              return;
                            }
                            setState(() {
                              frameType = value;
                              nameController.text = '';
                            });
                          },
                        ),
                      ),
                      ListTile(
                        enabled: !nontalkingEnabled,
                        title: const Text("Non-Talking Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.nontalking,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
                            if (nontalkingEnabled) {
                              showSnackbar(context,
                                  'A non-talking sprite already exists!');
                              return;
                            }
                            setState(() {
                              frameType = value;
                              nameController.text = '';
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("Expression Frame"),
                        leading: Radio<painter.FrameTypes>(
                          value: painter.FrameTypes.expression,
                          groupValue: frameType,
                          onChanged: (painter.FrameTypes? value) {
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

  void showSpriteNameDialog(BuildContext context, TextEditingController nameController, TextEditingController wxhController, void Function(void Function()) setState) {
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