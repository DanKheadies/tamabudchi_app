import 'package:flutter/material.dart';
import 'package:tamabudchi_app/barrel.dart';

class Tamabudchi extends StatelessWidget {
  const Tamabudchi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Standard')),
      body: SafeArea(
        // Build a responsive shell to maintain a center, square of pixels with
        // actions in horizontal & vertical spaces.
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth >= constraints.maxHeight;
            double barSize = 60;
            // Limiting-dimension
            double limen = isWide
                ? constraints.maxHeight
                : constraints.maxWidth;
            double limenAndBars = limen + (barSize * 2) + (barSize / 2);

            return Stack(
              children: [
                Center(
                  child: !isWide
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (constraints.maxHeight > limenAndBars) ...[
                              Container(
                                color: Colors.green.shade100,
                                height: barSize,
                                margin: EdgeInsets.only(bottom: barSize / 4),
                                width: double.infinity,
                              ),
                            ],
                            TamaGrid(),
                            if (constraints.maxHeight > limenAndBars) ...[
                              Container(
                                color: Colors.yellow.shade100,
                                height: barSize,
                                margin: EdgeInsets.only(top: barSize / 4),
                                width: double.infinity,
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (constraints.maxWidth > limenAndBars) ...[
                              Container(
                                color: Colors.green.shade100,
                                height: double.infinity,
                                margin: EdgeInsets.only(right: barSize / 4),
                                width: barSize,
                              ),
                            ],
                            TamaGrid(),
                            if (constraints.maxWidth > limenAndBars) ...[
                              Container(
                                color: Colors.yellow.shade100,
                                height: double.infinity,
                                margin: EdgeInsets.only(left: barSize / 4),
                                width: barSize,
                              ),
                            ],
                          ],
                        ),
                ),
                if (!isWide && constraints.maxHeight <= limenAndBars) ...[
                  Positioned(
                    top: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.green.shade100,
                        ),
                        height: barSize,
                        width: limen - limen / 50,
                      ),
                    ),
                  ),
                ],
                if (isWide && constraints.maxWidth < limenAndBars) ...[
                  Positioned(
                    top: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.green.shade100,
                        ),
                        height: limen - limen / 50,
                        width: barSize,
                      ),
                    ),
                  ),
                ],
                if (!isWide && constraints.maxHeight <= limenAndBars) ...[
                  Positioned(
                    bottom: limen / 100,
                    left: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.yellow.shade100,
                        ),
                        height: barSize,
                        width: limen - limen / 50,
                      ),
                    ),
                  ),
                ],
                if (isWide && constraints.maxWidth < limenAndBars) ...[
                  Positioned(
                    top: limen / 100,
                    right: limen / 100,
                    child: Opacity(
                      opacity: 0.75,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.yellow.shade100,
                        ),
                        height: limen - limen / 50,
                        width: barSize,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
