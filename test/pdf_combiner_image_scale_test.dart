import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_scale.dart';

void main() {
  group('ImageScale', () {
    test('should create an instance with given width and height', () {
      final scale = ImageScale(width: 100, height: 200);
      expect(scale.width, 100);
      expect(scale.height, 200);
    });

    test('original should have width and height as 0', () {
      expect(ImageScale.original.width, 0);
      expect(ImageScale.original.height, 0);
      expect(ImageScale.original.isOriginal, isTrue);
    });

    test('isOriginal should return false for non-original scales', () {
      final scale = ImageScale(width: 100, height: 200);
      expect(scale.isOriginal, isFalse);
    });
  });
}
