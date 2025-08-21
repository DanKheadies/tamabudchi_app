import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math.dart' as vmath;

class ContinousDragGesturesDetection extends StatefulWidget {
  const ContinousDragGesturesDetection({super.key});

  @override
  State<ContinousDragGesturesDetection> createState() =>
      _ContinousDragGesturesDetectionState();
}

class _ContinousDragGesturesDetectionState
    extends State<ContinousDragGesturesDetection> {
  final GlobalKey _parentKey = GlobalKey();
  final Set<int> selectedIndex = {};

  /// 20 seems like a good amount for kana
  int pixelCount = 15;
  int? activeIndex;
  List<int> indexList = [];
  // List<GlobalKey> keys = List.generate(25, (index) => GlobalKey());
  Offset dragPoint = Offset.zero;

  late List<GlobalKey> keys;

  @override
  void initState() {
    super.initState();

    keys = List.generate(pixelCount * pixelCount, (index) => GlobalKey());
  }

  _detectTapedItem(PointerEvent event) {
    dragPoint = event.localPosition;

    hitTestItems(event);
  }

  void _decreaseCount() {
    setState(() {
      --pixelCount;
      indexList = [];
      activeIndex = null;
    });
    keys = List.generate(pixelCount * pixelCount, (index) => GlobalKey());
  }

  void _increaseCount() {
    setState(() {
      ++pixelCount;
      indexList = [];
      activeIndex = null;
    });
    keys = List.generate(pixelCount * pixelCount, (index) => GlobalKey());
  }

  void hitTestItems(PointerEvent event) {
    final RenderBox box =
        _parentKey.currentContext!.findRenderObject() as RenderBox;

    final result = BoxHitTestResult();
    Offset local = box.globalToLocal(event.position);

    if (box.hitTest(result, position: local)) {
      for (final hit in result.path) {
        final target = hit.target;

        if (target is RenderBoxItemDraggable) {
          if (activeIndex != target.index) {
            // print('activeIndex: $activeIndex');
            // print('targetIndex: ${target.index}');
            setState(() {
              indexList.add(target.index);
            });
            print(indexList);
          }
          setState(() {
            activeIndex = target.index;
            selectedIndex.add(target.index);
            log(selectedIndex.length.toString());
          });
        }
      }
    }
  }

  // Calculates distance from center of the item to the drag point
  // and returns it as a value between 0 and 1 to use for various animations/effects
  double calculateDistanceValueFromDragPoint(GlobalKey key) {
    if (key.currentContext == null) {
      return 0;
    }
    if (_parentKey.currentContext == null) {
      return 0;
    }
    final RenderBox parent =
        _parentKey.currentContext!.findRenderObject() as RenderBox;
    final child =
        key.currentContext!.findRenderObject() as RenderBoxItemDraggable;
    final childCenter =
        child.localToGlobal(Offset.zero) +
        Offset(child.size.width / 2, child.size.height / 2);
    final childPositionWithingParent = parent.globalToLocal(childCenter);

    final dragPostionWithinParent = dragPoint;

    final childPositionVector = vmath.Vector2(
      childPositionWithingParent.dx,
      childPositionWithingParent.dy,
    );
    final dragPositionVector = vmath.Vector2(
      dragPostionWithinParent.dx,
      dragPostionWithinParent.dy,
    );
    final childCenterToDragPointCircleRadius = childPositionVector.distanceTo(
      dragPositionVector,
    );
    final childCoverageArea = child.size.width;
    final valueRatioToCenter =
        1 - (childCenterToDragPointCircleRadius / childCoverageArea);
    if (child.index == 4) {
      log(valueRatioToCenter.toString());
    }

    return valueRatioToCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF383838),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      "Select Index",
                      style: TextStyle(fontSize: 24, color: Colors.lightBlue),
                    ),
                  ),
                  Text(
                    activeIndex == null ? "None" : activeIndex.toString(),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "Pixel Count",
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  Text(
                    '$pixelCount x $pixelCount',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.add, size: 36, color: Colors.lightBlue),
                onPressed: pixelCount < 100 ? () => _increaseCount() : () {},
              ),
              IconButton(
                icon: Icon(Icons.remove, size: 36, color: Colors.lightBlue),
                onPressed: pixelCount > 1 ? () => _decreaseCount() : () {},
              ),
            ],
          ),
          const SizedBox(height: 30),
          Listener(
            key: _parentKey,
            onPointerMove: _detectTapedItem,
            onPointerDown: _detectTapedItem,
            onPointerUp: _detectTapedItem,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: pixelCount * pixelCount,
                padding: const EdgeInsets.all(0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: pixelCount,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  childAspectRatio: 1,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final isActive = activeIndex == index;
                  // final isSelected = selectedIndex.contains(index);
                  final key = keys[index];
                  final value = calculateDistanceValueFromDragPoint(key);
                  int derp =
                      255 -
                                  (indexList.length -
                                          indexList.lastIndexOf(index) +
                                          1) *
                                      2 <
                              0
                          ? 0
                          : 255 -
                              (indexList.length -
                                      indexList.lastIndexOf(index) +
                                      1) *
                                  2;
                  // 0 == been there very long / first mark; see thru
                  // 255 == most recent mark; full color
                  // In a list of 5 items, 4 should be 255 and 1 should be less
                  // but more than 175 (floor). It slowly goes to 175 as more
                  // items are added. So [2,   3,   10,  11,  21] would
                  // have something like [235, 240, 245, 250, 255].
                  // So, 255 - (length {5} - index+1 {1}) * length {5} = 235
                  // Or, 255 - (length {5} - index+1 {3}) * length {5} = 245
                  // Needs to be slower, like by 1
                  // [2,   3,   10,  11,  21]
                  // [235, 240, 245, 250, 255]
                  // 255 - (5 - 2) * 1
                  return ItemDraggable(
                    index: index,
                    key: key,
                    child: SizedBox(
                      // height: 90,
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            foregroundDecoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  // Colors.transparent,
                                  indexList.contains(index)
                                      ? Colors.red.withAlpha(derp)
                                      : Colors.transparent,
                                  const Color.fromARGB(
                                    255,
                                    0,
                                    0,
                                    0,
                                    // ).withOpacity(value.clamp(0, 1)),
                                    // ).withAlpha((value.clamp(0, 255)).toInt()),
                                  ).withAlpha(
                                    ((value * 255).clamp(0, 255)).toInt(),
                                  ),
                                ],
                                stops: const [0, 1.0],
                              ),
                              border: Border.all(
                                color: Color.fromARGB(255, 172, 230, 255),
                                // indexList.contains(index)
                                //     ? Colors.red
                                //     : Color.fromARGB(255, 172, 230, 255),
                                width: 2,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  isActive
                                      ? const Color(0xFFD3F2FF)
                                      : const Color.fromARGB(255, 64, 186, 239),
                                  const Color.fromARGB(255, 185, 227, 255),
                                ],
                                stops: const [0, 1],
                              ),
                              border: Border.all(
                                color: const Color.fromARGB(255, 172, 230, 255),
                                width: 2,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          TextButton(
            onPressed:
                () => setState(() {
                  indexList = [];
                  activeIndex = null;
                }),
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.lightBlue, fontSize: 42),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class ItemDraggable extends SingleChildRenderObjectWidget {
  const ItemDraggable({super.key, super.child, required this.index});
  final int index;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderBoxItemDraggable()..index = index;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBoxItemDraggable renderObject,
  ) {
    renderObject.index = index;
  }
}

class RenderBoxItemDraggable extends RenderProxyBox {
  late int index;
}
