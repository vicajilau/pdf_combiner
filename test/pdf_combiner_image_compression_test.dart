import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_compression.dart';

void main() {
  group('ImageCompression', () {
    test('should create predefined compression levels correctly', () {
      expect(ImageCompression.none.value, 0);
      expect(ImageCompression.low.value, 30);
      expect(ImageCompression.medium.value, 60);
      expect(ImageCompression.high.value, 100);
    });

    test('should create custom compression level correctly', () {
      final quality = ImageCompression.custom(75);
      expect(quality.value, 75);
    });

    test('should throw assertion error for invalid quality values', () {
      expect(() => ImageCompression.custom(-1), throwsA(isA<AssertionError>()));
      expect(
          () => ImageCompression.custom(101), throwsA(isA<AssertionError>()));
    });
  });
}
