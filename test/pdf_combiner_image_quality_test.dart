import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_quality.dart';

void main() {
  group('ImageQuality', () {
    test('should create predefined quality levels correctly', () {
      expect(ImageQuality.low.value, 30);
      expect(ImageQuality.medium.value, 60);
      expect(ImageQuality.high.value, 100);
    });

    test('should create custom quality level correctly', () {
      final quality = ImageQuality.custom(75);
      expect(quality.value, 75);
    });

    test('should throw assertion error for invalid quality values', () {
      expect(() => ImageQuality.custom(0), throwsA(isA<AssertionError>()));
      expect(() => ImageQuality.custom(101), throwsA(isA<AssertionError>()));
    });
  });
}
