import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/tools/sprite_tools.dart';
import 'package:gooftuber_editor/views/dialogs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;

Future<String?> showCodeDialog(context) {
  var controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];


  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the Upload-Code that Gooftuber Studio provided you."),
              const SizedBox(height: 16,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 6; i++)
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: controllers[i],
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 1) {
                            if (i < 5) {
                              FocusScope.of(context).nextFocus();
                            } else {
                              FocusScope.of(context).unfocus();
                            }
                          }
                        },
                      ),
                    )
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () {
              var url = "https://docs.awesomesauce.software/books/gooftuber/page/syncing-avatars-from-editor-to-studio";
              launchUrl(Uri.parse(url));
            }, child: const Text('Help')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                var code = '';
                for (var i = 0; i < 6; i++) {
                  code += controllers[i].text;
                }
                Navigator.pop(context, code);
              },
              child: const Text('Add'),
            ),
          ],
        );
      });
}

void editNameDialog(
    BuildContext context,
    int i,
    TextEditingController nameController,
    void Function(void Function()) setState) {
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
                      onTap: () {
                        if (talkingEnabled) {
                          showSnackbar(
                              context, 'A talking sprite already exists!');
                        } else {
                          setState(() {
                            frameType = painter.FrameTypes.talking;
                            nameController.text = '';
                          });
                        }
                      },
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
                      onTap: () {
                        if (nontalkingEnabled) {
                          showSnackbar(context,
                              'A non-talking sprite already exists!');
                        } else {
                          setState(() {
                            frameType = painter.FrameTypes.nontalking;
                            nameController.text = '';
                          });
                        }
                      },
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
                      onTap: () {
                        setState(() {
                          frameType = painter.FrameTypes.expression;
                        });
                      },
                    ),
                  ],
                ),
                if (frameType == painter.FrameTypes.expression)
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
                      child: TextField(
                            decoration: const InputDecoration(
                              label: Text('Sprite Name'),
                              border: OutlineInputBorder(),
                              hintText: 'Enter Frame Type',
                            ),
                            textAlign: TextAlign.center,
                            controller: nameController,
                            onSubmitted: (String value) {
                              if (value == '' &&
                                  frameType == painter.FrameTypes.expression) {
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

void showSpriteNameDialog(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController wxhController,
    void Function(void Function()) setState) {
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
                      onTap: () {
                        if (doesTalkingExist()) {
                          showSnackbar(context,
                              'A talking sprite already exists! Please delete it before creating a new one.');
                        } else {
                          setState(() {
                            frameType = painter.FrameTypes.talking;
                          });
                        }
                      },
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
                      onTap: () {
                        if (doesNonTalkingExist()) {
                          showSnackbar(context,
                              'A non-talking sprite already exists! Please delete it before creating a new one.');
                        } else {
                          setState(() {
                            frameType = painter.FrameTypes.nontalking;
                          });
                        }
                      },
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
                      onTap: () {
                        if (!expressionEnabled) {
                          showSnackbar(context,
                              'You must create a talking and/or non-talking sprite before creating an expression sprite.');
                        } else {
                          setState(() {
                            frameType = painter.FrameTypes.expression;
                          });
                        }
                      },
                    ),
                  ],
                ),
                // radio buttons for sprite type
                if (frameType == painter.FrameTypes.expression)
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
                      child: TextField(
                            decoration: const InputDecoration(
                              label: Text('Sprite Name'),
                              border: OutlineInputBorder(),
                              hintText: 'Enter Frame Type',
                            ),
                            textAlign: TextAlign.center,
                            controller: nameController,
                            onSubmitted: (String value) {
                              if (value == '' &&
                                  frameType == painter.FrameTypes.expression) {
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
                                              j < int.parse(wxhController.text);
                                              j++)
                                            painter.Pixel(Colors.transparent)
                                        ]
                                    ],
                                    frameType!));
                              });

                              nameController.text = '';

                              Navigator.pop(context);
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
                        for (var i = 0; i < int.parse(wxhController.text); i++)
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
