import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamabudchi_app/barrel.dart';

/// Opens the dialog from a plain button and records what it returns.
Future<void> _openDialog(
  WidgetTester tester,
  void Function(FrameTiming?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            onResult(await showFrameTimeDialog(context, 400, 25));
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle(); // wait for the dialog to animate in
}

void main() {
  testWidgets('Set returns the typed time and the jitter', (tester) async {
    FrameTiming? result;
    await _openDialog(tester, (r) => result = r);

    await tester.enterText(find.byType(TextField), '300');
    await tester.pump();
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(result?.frameMs, 300);
    expect(result?.jitterPercent, 25);
  });

  testWidgets('Set is disabled for a time below the minimum', (tester) async {
    await _openDialog(tester, (_) {});

    await tester.enterText(find.byType(TextField), '5');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Set'),
    );
    expect(button.onPressed, isNull);
  });
}
