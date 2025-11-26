
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_scale.dart';

void main() {
  group('ImageScale', () {
    test('default values', () {
      final scale = ImageScale.original;
      expect(scale.width, 0);
      expect(scale.height, 0);
      expect(scale.isOriginal, isTrue);
    });

    test('constructor assigns values', () {
      final scale = ImageScale(width: 100, height: 200);
      expect(scale.width, 100);
      expect(scale.height, 200);
      expect(scale.isOriginal, isFalse);
    });

    test('toMap returns correct map', () {
      final scale = ImageScale(width: 100, height: 200);
      expect(scale.toMap(), {'width': 100, 'height': 200});
    });
  });
}
