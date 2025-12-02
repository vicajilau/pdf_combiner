
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';

void main() {
  group('PdfFromMultipleImageConfig', () {
    test('default values', () {
      final config = PdfFromMultipleImageConfig();
      expect(config.rescale.isOriginal, isTrue);
      expect(config.keepAspectRatio, isTrue);
    });

    test('constructor assigns values', () {
      final scale = ImageScale(width: 100, height: 200);
      final config = PdfFromMultipleImageConfig(
        rescale: scale,
        keepAspectRatio: false,
      );
      expect(config.rescale, scale);
      expect(config.keepAspectRatio, isFalse);
    });

    test('toMap returns correct map', () {
      final scale = ImageScale(width: 100, height: 200);
      final config = PdfFromMultipleImageConfig(
        rescale: scale,
        keepAspectRatio: false,
      );
      expect(config.toMap(), {
        'rescale': {'width': 100, 'height': 200},
        'keepAspectRatio': false,
      });
    });
  });
}
