import 'package:flutter/material.dart';
import 'package:tamabudchi_app/tetris/pixel.dart';
import 'package:tamabudchi_app/tetris/values.dart';

class PixelHeroBoard extends StatefulWidget {
  const PixelHeroBoard({super.key});

  @override
  State<PixelHeroBoard> createState() => _PixelHeroBoardState();
}

class _PixelHeroBoardState extends State<PixelHeroBoard> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              color: Colors.lightBlue,
              child: Center(child: Text('Characters')),
            ),
            Container(
              width: double.infinity,
              height: 100,
              color: Colors.lightGreen,
              child: Center(
                child: Text(
                  'Suggested Characters (1-to-many) (post draw); translation output',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 50,
              color: Colors.amberAccent,
              child: Center(
                child: Text('Commands (backspace, alt. translator API, etc)'),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 9,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onHorizontalDragStart: (details) => print('drag: $index'),
                  child: Pixel(color: Colors.grey[800]!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
