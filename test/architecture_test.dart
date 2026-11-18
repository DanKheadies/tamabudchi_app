import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('models import nothing from the app layers above them', () {
    final files = Directory(
      'lib/models',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final imports = file.readAsLinesSync().where(
        (line) => line.trimLeft().startsWith('import '),
      );
      for (final line in imports) {
        expect(
          line.contains('package:tamabudchi_app/'),
          isFalse,
          reason: '${file.path}: $line',
        );
      }
    }
  });
}
