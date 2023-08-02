import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gooftuber_editor/main.dart';
import 'package:gooftuber_editor/views/painter.dart' as painter;

class SpritePreview extends StatefulWidget {
  const SpritePreview({super.key});

  @override
  State<SpritePreview> createState() => _SpritePreviewState();
}

class _SpritePreviewState extends State<SpritePreview> {

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final TransformationController _controller = TransformationController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imageSelected,
      builder: (context, value, child) {
        if (sprites.isEmpty) {
          return const Center(child: Text("There are no Images to preview."),);
        }
        return Scaffold(
        appBar: AppBar(
          title: Text('Sprite Preview - ${sprites[value].frameType == painter.FrameTypes.expression ? sprites[value].name : sprites[value].frameType.toString().split('.').last}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  imageSelected.value = (imageSelected.value - 1 == -1) ? sprites.length - 1 : imageSelected.value - 1;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  imageSelected.value = (imageSelected.value + 1 == sprites.length) ? 0 : imageSelected.value + 1;
                });
              },
            ),
          ],
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          onScaleUpdate: (ScaleUpdateDetails details) {
            setState(() {
              // We want to update the scale based on the updated scroll.
              double scaleFactor = _controller.value.getMaxScaleOnAxis();
              double delta = details.scale / scaleFactor;
              // Update the scale in controller.
              _controller.value = Matrix4.diagonal3Values(
                delta,
                delta,
                1.0,
              )..multiply(_controller.value);
            });
          },
          child: InteractiveViewer(
            transformationController: _controller,
            boundaryMargin: EdgeInsets.all(sprites[value].width*2),
            minScale: 0.1,
            maxScale: 10.0,
            child: Image.memory(Uint8List.fromList(sprites[value].saveAsPng()),
            filterQuality: FilterQuality.none,
            ),
          ),
        );
      },
    )
        )
      );
      },
    );
  }
}