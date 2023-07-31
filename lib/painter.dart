import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// struct of image, contains pixel data, width, height, and name
class Image {
  Image(this.name, this.width, this.height, this.pixels);
  String name;
  int width;
  int height;
  List<List<Pixel>> pixels =
      List.generate(128, (i) => List.generate(128, (j) => Pixel(Colors.white)));

  void updatePixel(int row, int col, Color color) {
    pixels[row][col].color = color;
  }
}

// struct of pixel, contains color
class Pixel {
  Pixel(this.color);
  ui.Color color;
}

// painter class, contains image and paint function. IS ALWAYS SQUARE
class Painter extends StatefulWidget {
  final Image image;

  const Painter({super.key, required this.image});
  @override
  // ignore: library_private_types_in_public_api
  _PainterState createState() => _PainterState();
}

enum Tool { brush, eraser, rectangle, line, circle, fill }

class _PainterState extends State<Painter> {
  // variables
  Tool tool = Tool.brush;
  double _width = 0;
  double _height = 0;
  double brushSize = 1;
  double _initialX = 0;
  double _initialY = 0;
  double _x = 0;
  double _y = 0;
  bool showGrid = false;
  bool _isPainting = false;
  Color _color = Colors.black;
  Color _backgroundColor = Colors.grey;
  List<List<Pixel>> _pixels =
      List.generate(128, (i) => List.generate(128, (j) => Pixel(Colors.white)));

  void editPixel(col, row) {
    switch (tool) {
      case Tool.brush:
        _pixels[row][col].color = _color;
        
        break;
      case Tool.eraser:
        setState(() {
          _pixels[row][col].color = Colors.transparent;
        });
        break;
      case Tool.rectangle:
        break;
      case Tool.line:
        setState(() {
          if (_isPainting) {
            if (_initialX == -1) _initialX = col.toDouble();
            if (_initialY == -1) _initialY = row.toDouble();
            _x = col.toDouble();
            _y = row.toDouble();
          } else {
            // draw line from initial to final
            
            for (int i = min(_initialX, _x).toInt();
                i < max(_initialX, _x).toInt();
                i++) {
              for (int j = min(_initialY, _y).toInt();
                  j < max(_initialY, _y).toInt();
                  j++) {
                _pixels[j][i].color = _color;
              }
            }

            _initialX = -1;
            _initialY = -1;
          }
        });
        break;
      case Tool.circle:
        break;
      case Tool.fill:
        setState(() {
          
        });
        break;
    }
  }

  // init function
  @override
  void initState() {
    super.initState();
    _pixels = widget.image.pixels;
  }

  // paint function
  @override
  Widget build(BuildContext context) {
    // get screen size
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;

    // return widget
    return Container(
      color: _backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(children: [
                    IconButton(
                      icon: Icon(Icons.brush),
                      onPressed: () {
                        // toggle brush size
                        setState(() {
                          if (brushSize == 1) {
                            brushSize = 5;
                          } else {
                            brushSize = 1;
                          }
                        });
                      },
                    ),
                    Slider(
                        value: brushSize,
                        onChanged: (value) {
                          setState(() {
                            brushSize = value;
                          });
                        },
                        onChangeEnd: (value) {
                          // unfocus slider
                          FocusScope.of(context).requestFocus(new FocusNode());
                        },
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: brushSize.toString()),
                  ]),
                ),
                Expanded(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      IconButton(
                        icon: Icon(Icons.color_lens),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Select a color!"),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      portraitOnly: true,
                                      pickerAreaHeightPercent: 0.5,
                                      labelTypes: const [ColorLabelType.rgb],
                                      enableAlpha: false,
                                      pickerColor: _color,
                                      onColorChanged: (color) {
                                        setState(() {
                                          _color = color;
                                        });
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Close"),
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
                      IconButton(isSelected: showGrid, icon: Icon(Icons.grid_3x3), onPressed: () {
                        setState(() {
                          showGrid = !showGrid;
                        });
                      },),
                      IconButton(
                        icon: Icon(Icons.format_paint_rounded),
                        onPressed: () {
                          // toggle background color
                          setState(() {
                            if (_backgroundColor == Colors.grey) {
                              // if brightness is bright, use white.
                              _backgroundColor = Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const ui.Color.fromARGB(255, 255, 255, 255)
                                  : const ui.Color.fromARGB(0, 69, 69, 69);
                            } else {
                              _backgroundColor = Colors.grey;
                            }
                          });
                        },
                      ),
                    ])),
                Expanded(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                      // eraser
                      IconButton(
                          isSelected: tool == Tool.eraser,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              tool = Tool.eraser;
                            });
                          }),
                      IconButton(
                          isSelected: tool == Tool.brush,
                          icon: const Icon(Icons.brush),
                          onPressed: () {
                            setState(() {
                              tool = Tool.brush;
                            });
                          }),
                      // IconButton(
                      //     isSelected: tool == Tool.rectangle,
                      //     icon: const Icon(Icons.rectangle),
                      //     onPressed: () {
                      //       setState(() {
                      //         tool = Tool.rectangle;
                      //       });
                      //     }),
                      // IconButton(
                      //     isSelected: tool == Tool.line,
                      //     icon: const Icon(Icons.line_weight),
                      //     onPressed: () {
                      //       setState(() {
                      //         tool = Tool.line;
                      //       });
                      //     }),
                      // IconButton(
                      //     isSelected: tool == Tool.circle,
                      //     icon: const Icon(Icons.circle),
                      //     onPressed: () {
                      //       setState(() {
                      //         tool = Tool.circle;
                      //       });
                      //     }),
                      // IconButton(
                      //     isSelected: tool == Tool.fill,
                      //     icon: const Icon(Icons.format_color_fill),
                      //     onPressed: () {
                      //       setState(() {
                      //         tool = Tool.fill;
                      //       });
                      //     }),
                    ]))
              ],
            ),
          ),
          SizedBox(
            // use the smaller dimension
            width: min(_width, _height) - 144,
            height: min(_width, _height) - 144,
            child: Container(
              color: _backgroundColor,
              child: Center(
                child: SizedBox(
                  width: min(_width, _height) - 144,
                  height: min(_width, _height) - 144,
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (details) {
                        setState(() {
                          _isPainting = true;
                          _x = details.localPosition.dx;
                          _y = details.localPosition.dy;
                          double maxSize = min(_width, _height) - 144;
                          int row =
                              (_y / maxSize * widget.image.height).floor();
                          int col = (_x / maxSize * widget.image.width).floor();
                          row = max(0, row);
                          row = min(widget.image.width - 1, row);
                          col = max(0, col);
                          col = min(widget.image.height - 1, col);
                          if (brushSize == 1) {
                            editPixel(col, row);
                          } else {
                            // initialize drawExtra with empty list the size of brushSize
                            for (int i = 0; i < brushSize; i++) {
                              for (int j = 0; j < brushSize; j++) {
                                if (row + i >= widget.image.height) continue;
                                if (col + j >= widget.image.width) continue;
                                editPixel(col, row);
                              }
                            }
                          }
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _x = details.localPosition.dx;
                          _y = details.localPosition.dy;
                          double maxSize = min(_width, _height) - 144;
                          int row =
                              (_y / maxSize * widget.image.height).floor();
                          int col = (_x / maxSize * widget.image.width).floor();
                          row = max(0, row);
                          row = min(widget.image.width - 1, row);
                          col = max(0, col);
                          col = min(widget.image.height - 1, col);
                          if (brushSize == 1) {
                            editPixel(col, row);
                          } else {
                            // initialize drawExtra with empty list the size of brushSize
                            for (int i = 0; i < brushSize; i++) {
                              for (int j = 0; j < brushSize; j++) {
                                if (row + i >= widget.image.height) continue;
                                if (col + j >= widget.image.width) continue;
                                editPixel(col, row);
                              }
                            }
                          }
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _isPainting = false;
                        });
                      },
                      child: CustomPaint(
                          painter: PainterWidget(_pixels, showGrid),
                          size: Size(_width > _height ? _height : _width,
                              _width > _height ? _height : _width))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// painter widget
class PainterWidget extends CustomPainter {
  PainterWidget(this.pixels, this.grid);
  List<List<Pixel>> pixels;
  bool grid;
  @override
  void paint(Canvas canvas, Size size) {
    // draw grid
    if (grid) {
for (int i = 0; i < pixels.length; i++) {
      for (int j = 0; j < pixels[i].length; j++) {
        Paint paint = Paint();
        paint.color = Colors.black;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = .01;
        canvas.drawRect(
          Rect.fromLTWH(
              j * size.width / pixels[j].length,
              i * size.height / pixels.length,
              size.width / pixels[j].length,
              size.height / pixels.length),
          paint,
        );
      }
    }
    }
    // draw pixels
    for (int i = 0; i < pixels.length; i++) {
      for (int j = 0; j < pixels[i].length; j++) {
        Paint paint = Paint();
        paint.color = pixels[i][j].color;
        canvas.drawRect(
          Rect.fromLTWH(
              j * size.width / pixels[j].length,
              i * size.height / pixels.length,
              size.width / pixels[j].length,
              size.height / pixels.length),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PainterWidget oldDelegate) {
    return true;
  }
}
