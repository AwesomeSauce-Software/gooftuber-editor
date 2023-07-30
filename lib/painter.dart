import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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

class _PainterState extends State<Painter> {
  // variables
  double _width = 0;
  double _height = 0;
  double _pixelSize = 0;
  double brushSize = 1;
  double _x = 0;
  double _y = 0;
  // ignore: unused_field
  bool _isPainting = false;
  // TODO: Add color picker
  // ignore: prefer_final_fields
  Color _color = Colors.black;
  Color _backgroundColor = Colors.grey;
  List<List<Pixel>> _pixels =
      List.generate(128, (i) => List.generate(128, (j) => Pixel(Colors.white)));

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
    _pixelSize = _width / 128;

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
                      child:
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      icon: Icon(Icons.color_lens),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.format_paint_rounded),
                      onPressed: () {
                        // toggle background color
                        setState(() {
                          if (_backgroundColor == Colors.grey) {
                            _backgroundColor = Colors.white;
                          } else {
                            _backgroundColor = Colors.grey;
                          }
                        });
                      },
                    ),
                  ])),
                  Expanded(
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(isSelected: true, icon: Icon(Icons.brush), onPressed: () {}),
                    IconButton(icon: Icon(Icons.rectangle), onPressed: () {}),
                    IconButton(icon: Icon(Icons.line_weight), onPressed: () {}),
                    IconButton(icon: Icon(Icons.circle), onPressed: () {}),
                    IconButton(icon: Icon(Icons.format_color_fill), onPressed: () {}),
                  ]))
                ],
              ),
            ),
            SizedBox(
              // use the smaller dimension
              width: (_width > _height ? _height : _width) -144,
              height: (_width > _height ? _height : _width) -144,
              child: Container(
                color: _backgroundColor,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _isPainting = true;
                      _x = details.localPosition.dx;
                      _y = details.localPosition.dy;
                      if (_x < 0) _x = 0;
                      if (_y < 0) _y = 0;
                      if (_x > _width) _x = _width;
                      if (_y > _height) _y = _height;
                      _pixels[(_y / _pixelSize).floor()][(_x / _pixelSize).floor()]
                          .color = _color;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _x = details.localPosition.dx;
                      _y = details.localPosition.dy;
                      if (_x < 0) _x = 0;
                      if (_y < 0) _y = 0;
                      if (_x > _width) _x = _width;
                      if (_y > _height) _y = _height;
                      _pixels[(_y / _pixelSize).floor()][(_x / _pixelSize).floor()]
                          .color = _color;
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _isPainting = false;
                    });
                  },
                  child: Center(
                    child: SizedBox(
                        width: _width > _height ? _height : _width,
                        height: _width > _height ? _height : _width,
                        child: CustomPaint(
                            painter: PainterWidget(_pixels),
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
  PainterWidget(this.pixels);
  List<List<Pixel>> pixels;
  @override
  void paint(Canvas canvas, Size size) {
    // draw pixels
    for (int i = 0; i < pixels.length; i++) {
      for (int j = 0; j < pixels[i].length; j++) {
        Paint paint = Paint();
        paint.color = pixels[i][j].color;
        canvas.drawRect(
          Rect.fromLTWH(j * size.width / 128, i * size.height / 128,
              size.width / 128, size.height / 128),
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
