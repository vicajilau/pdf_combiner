
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_compression.dart';

void main() {
  group('ImageCompression', () {
    test('predefined values', () {
      expect(ImageCompression.none.value, 0);
      expect(ImageCompression.low.value, 30);
      expect(ImageCompression.medium.value, 60);
      expect(ImageCompression.high.value, 100);
    });

    test('custom value', () {
      final compression = ImageCompression.custom(50);
      expect(compression.value, 50);
    });

    test('custom value assertion', () {
      expect(() => ImageCompression.custom(-1), throwsA(isA<AssertionError>()));
      expect(() => ImageCompression.custom(101), throwsA(isA<AssertionError>()));
    });
  });
}
