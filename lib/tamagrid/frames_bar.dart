import 'package:flutter/material.dart';

class FramesBar extends StatelessWidget {
  final bool isHorizontal;
  final bool? isFloating;
  final double barSize;
  final double? limen;
  final Function() cycleFrameSet;

  const FramesBar({
    super.key,
    required this.barSize,
    required this.cycleFrameSet,
    required this.isHorizontal,
    this.isFloating = false,
    this.limen = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isFloating! ? 15 : 0),
        color: Colors.yellow.shade100,
      ),
      height: isHorizontal
          ? barSize
          : isFloating!
          ? limen! - limen! / 50
          : double.infinity,
      margin: isHorizontal
          ? EdgeInsets.only(top: barSize / 4)
          : EdgeInsets.only(left: barSize / 4),
      width: !isHorizontal
          ? barSize
          : isFloating!
          ? limen! - limen! / 50
          : double.infinity,
      child: isHorizontal
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Center(
                  child: IconButton(
                    color: Colors.deepPurple,
                    icon: Icon(Icons.cyclone),
                    onPressed: cycleFrameSet,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Center(
                  child: IconButton(
                    color: Colors.deepPurple,
                    icon: Icon(Icons.cyclone),
                    onPressed: cycleFrameSet,
                  ),
                ),
              ],
            ),
    );
  }
}
