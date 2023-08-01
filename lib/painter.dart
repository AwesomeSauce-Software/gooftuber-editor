import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:pixelart/main.dart';
import 'package:pixelart/tools/sprite_tools.dart';

enum FrameTypes { talking, nontalking, expression }

// struct of image, contains pixel data, width, height, and name
class Image {
  Image(this.name, this.width, this.height, this.pixels, this.frameType);
  String name;
  int width;
  int height;
  FrameTypes frameType;
  String path = "";
  List<List<Pixel>> pixels;

  void updatePixel(int row, int col, Color color) {
    pixels[row][col].color = color;
  }

  List<int> saveAsPng() {
    var png = img.Image(width: width, height: height, numChannels: 4);

    for (int i = 0; i < pixels.length; i++) {
      for (int j = 0; j < pixels[i].length; j++) {
        png.setPixelRgba(j, i, pixels[i][j].color.red, pixels[i][j].color.green,
            pixels[i][j].color.blue, pixels[i][j].color.alpha);
      }
    }
    return img.encodePng(png);
  }

  Image copy(String nameAppendix) {
    return Image(name += nameAppendix, width, height, pixels, frameType);
  }
}

List<List<Pixel>> loadFromPng(List<int> bytes) {
  Uint8List uint8list = Uint8List.fromList(bytes);
  img.Image png = img.decodeImage(uint8list)!;

  List<List<Pixel>> pixels = List.generate(
      png.height,
      (i) => List.generate(png.width, (j) {
            // Get the pixel from the png object
            img.Pixel pixel = png.getPixel(j, i);

            // Get the rgba channels from the pixel
            int r = pixel.r.toInt();
            int g = pixel.g.toInt();
            int b = pixel.b.toInt();
            int a = pixel.a.toInt();

            // Create a Color object
            ui.Color color = ui.Color.fromARGB(a, r, g, b);

            return Pixel(color, empty: false);
          }));

  return pixels;
}

// struct of pixel, contains color
class Pixel {
  Pixel(this.color, {this.empty = false});
  ui.Color color;
  bool empty;
}

// painter class, contains image and paint function. IS ALWAYS SQUARE
class Painter extends StatefulWidget {
  const Painter({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _PainterState createState() => _PainterState();
}

enum Tool { brush, eraser, rectangle, line, circle, fill, pick }

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
  Color _backgroundColor = Colors.transparent;
  List<List<Pixel>> _pixels = [];

  Image editPixel(int selected, int col, int row) {
    switch (tool) {
      case Tool.brush:
        _pixels[row][col].color = _color;
        sprites[selected].pixels = _pixels;
        break;
      case Tool.eraser:
        setState(() {
          _pixels[row][col].color = Colors.transparent;
          sprites[selected].pixels = _pixels;
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

            sprites[selected].pixels = _pixels;

            _initialX = -1;
            _initialY = -1;
          }
        });
        break;
      case Tool.circle:
        break;
      case Tool.fill:
        setState(() {
          List<List<Pixel>> newPixels = List.generate(
              sprites[selected].height,
              (i) => List.generate(sprites[selected].width,
                  (j) => Pixel(Colors.transparent, empty: true)));
          List<List<bool>> visited = List.generate(sprites[selected].height,
              (i) => List.generate(sprites[selected].width, (j) => false));
          List<List<int>> queue = [];
          queue.add([row, col]);
          while (queue.isNotEmpty) {
            List<int> current = queue.removeAt(0);
            int r = current[0];
            int c = current[1];
            if (r < 0 || r >= sprites[selected].height) continue;
            if (c < 0 || c >= sprites[selected].width) continue;
            if (visited[r][c]) continue;
            visited[r][c] = true;
            if (_pixels[r][c].color == _pixels[row][col].color) {
              newPixels[r][c].color = _color;
              newPixels[r][c].empty = false;
              queue.add([r + 1, c]);
              queue.add([r - 1, c]);
              queue.add([r, c + 1]);
              queue.add([r, c - 1]);
            } else {
              newPixels[r][c].color = _pixels[r][c].color;
            }
          }

          for (int i = 0; i < sprites[selected].height; i++) {
            for (int j = 0; j < sprites[selected].width; j++) {
              if (newPixels[i][j].empty) {
                newPixels[i][j].color = _pixels[i][j].color;
                newPixels[i][j].empty = false;
              }
            }
          }
          _pixels = newPixels;
          sprites[selected].pixels = _pixels;
        });
        break;
      case Tool.pick:
        setState(() {
          _color = _pixels[row][col].color;
        });
        break;
    }
    return sprites[selected];
  }

  // init function
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final TransformationController _controller = TransformationController();

  // paint function
  @override
  Widget build(BuildContext context) {
    // get screen size
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;

    // return widget
    return ValueListenableBuilder(
        valueListenable: imageSelected,
        builder: (_, selected, __) {
          _pixels = sprites[(selected != -1) ? selected : 0].pixels;
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
                            tooltip: 'Brush size toggle',
                            icon: const Icon(Icons.brush),
                            onPressed: tool != Tool.fill
                                ? () {
                                    // toggle brush size
                                    setState(() {
                                      if (brushSize == 1) {
                                        brushSize = 5;
                                      } else {
                                        brushSize = 1;
                                      }
                                    });
                                  }
                                : null,
                          ),
                          Slider(
                            // show slider value below slider
                              value: brushSize,
                              onChanged: (value) {
                                setState(() {
                                  brushSize = value;
                                });
                              },
                              onChangeEnd: (value) {
                                // unfocus slider
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                              },
                              min: 1,
                              max: 10,
                              divisions: 9),
                        ]),
                      ),
                      Expanded(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            // eraser
                            IconButton(
                                tooltip: 'Eraser',
                                isSelected: tool == Tool.eraser,
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    tool = Tool.eraser;
                                  });
                                }),
                            IconButton(
                                tooltip: 'Brush',
                                isSelected: tool == Tool.brush,
                                icon: const Icon(Icons.brush),
                                onPressed: () {
                                  setState(() {
                                    tool = Tool.brush;
                                  });
                                }),
                            IconButton(
                                tooltip: 'Fill',
                                isSelected: tool == Tool.fill,
                                icon: const Icon(Icons.format_color_fill),
                                onPressed: () {
                                  setState(() {
                                    tool = Tool.fill;
                                  });
                                }),
                          ])),
                      Expanded(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                              tooltip: 'Color picker',
                              icon: const Icon(Icons.color_lens),
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
                                            labelTypes: const [
                                              ColorLabelType.rgb
                                            ],
                                            enableAlpha: true,
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
                                            child: const Text("Close"),
                                          ),
                                        ],
                                      );
                                    });
                              },
                            ),
                            // IconButton(
                            //   isSelected: tool == Tool.pick,
                            //   icon: const Icon(Icons.colorize_rounded),
                            //   onPressed: () {
                            //     setState(() {
                            //       tool = Tool.pick;
                            //     });
                            //   },
                            // ),
                            IconButton(
                              tooltip: 'Toggle grid',
                              isSelected: showGrid,
                              icon: const Icon(Icons.grid_3x3),
                              onPressed: () {
                                setState(() {
                                  showGrid = !showGrid;
                                });
                              },
                            ),
                            IconButton(
                              tooltip: 'Toggle background color',
                              icon: const Icon(Icons.format_paint_rounded),
                              onPressed: () {
                                // toggle background color
                                setState(() {
                                  if (_backgroundColor == Colors.grey) {
                                    // if brightness is bright, use white.
                                    _backgroundColor = Colors.transparent;
                                  } else {
                                    _backgroundColor = Colors.grey;
                                  }
                                });
                              },
                            ),
                          ]))
                    ],
                  ),
                ),
                SizedBox(
                  // use the smaller dimension
                  width: min(_width, _height) - 88,
                  height: min(_width, _height) - 88,
                  child: Container(
                    color: _backgroundColor,
                    child: Center(
                      child: SizedBox(
                        width: min(_width, _height) - 88,
                        height: min(_width, _height) - 88,
                        child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) {
                              setState(() {
                                _isPainting = true;
                                var list = spriteBefore.value;
                                list.insert(0, sprites[selected]);
                                spriteBefore.value = list;
                                spriteRedo.value = [];
                                sprites[selected] =
                                    doPaint(details.localPosition, selected);
                                sprites[selected].pixels = _pixels;
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                sprites[selected] =
                                    doPaint(details.localPosition, selected);
                                sprites[selected].pixels = _pixels;
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                _isPainting = false;
                              });
                            },
                            child: CustomPaint(
                                painter: PainterWidget(_pixels, showGrid, background: sprites[selected].frameType == FrameTypes.expression ? getPrimaryImage()?.pixels : null),
                                size: Size(_width > _height ? _height : _width,
                                    _width > _height ? _height : _width))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Image doPaint(Offset localPosition, selected) {
    _x = localPosition.dx;
    _y = localPosition.dy;
    double maxSize = min(_width, _height) - 88;
    int row = (_y / maxSize * sprites[selected].height).floor();
    int col = (_x / maxSize * sprites[selected].width).floor();
    row = max(0, row);
    row = min(sprites[selected].width - 1, row);
    col = max(0, col);
    col = min(sprites[selected].height - 1, col);
    if (brushSize == 1) {
      sprites[selected] = editPixel(selected, col, row);
      return sprites[selected];
    } else {
      // initialize drawExtra with empty list the size of brushSize
      // center brush on cursor
      int brushSizeHalf = (brushSize / 2).floor();
      for (int i = -brushSizeHalf; i <= brushSizeHalf; i++) {
        for (int j = -brushSizeHalf; j <= brushSizeHalf; j++) {
          if (i * i + j * j <= brushSizeHalf * brushSizeHalf) {
            // check if in bounds
            if (col + i >= 0 &&
                col + i < sprites[selected].width &&
                row + j >= 0 &&
                row + j < sprites[selected].height) {
              sprites[selected] = editPixel(selected, col + i, row + j);
            }
          }
        }
      }
    }
    return sprites[selected];
  }
}

// painter widget
class PainterWidget extends CustomPainter {
  PainterWidget(this.pixels, this.grid, {this.background});
  List<List<Pixel>> pixels;
  List<List<Pixel>>? background;
  bool grid;
  @override
  void paint(Canvas canvas, Size size) {
    // draw border
    Paint borderPaint = Paint();
    borderPaint.isAntiAlias = false;
    borderPaint.color = Colors.black;
    borderPaint.style = PaintingStyle.stroke;
    borderPaint.strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    // draw grid
    if (grid) {
      for (int i = 0; i < pixels.length; i++) {
        for (int j = 0; j < pixels[i].length; j++) {
          Paint paint = Paint();
          paint.color = Colors.black;
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = .05;
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
    // draw background if it exists
    if (background != null) {
      debugPrint('has background');
      for (int i = 0; i < background!.length; i++) {
        for (int j = 0; j < background![i].length; j++) {
          Paint paint = Paint();
          paint.isAntiAlias = false;
          // set opacity
          paint.color = background![i][j].color;
          if (background![i][j].color != Colors.transparent) {
            paint.color = background![i][j].color.withOpacity(.5);
          }
          paint.style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromLTWH(
                j * size.width / background![j].length,
                i * size.height / background!.length,
                size.width / background![j].length,
                size.height / background!.length),
            paint,
          );
        }
      }
    }
    // draw pixels
    for (int i = 0; i < pixels.length; i++) {
      for (int j = 0; j < pixels[i].length; j++) {
        Paint paint = Paint();
        paint.isAntiAlias = false;
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
