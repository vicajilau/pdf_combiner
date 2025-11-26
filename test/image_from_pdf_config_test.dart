
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/image_compression.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';

void main() {
  group('ImageFromPdfConfig', () {
    test('default values', () {
      final config = ImageFromPdfConfig();
      expect(config.rescale.isOriginal, isTrue);
      expect(config.compression, ImageCompression.none);
      expect(config.createOneImage, isFalse);
    });

    test('constructor assigns values', () {
      final scale = ImageScale(width: 100, height: 200);
      final compression = ImageCompression.custom(50);
      final config = ImageFromPdfConfig(
        rescale: scale,
        compression: compression,
        createOneImage: true,
      );
      expect(config.rescale, scale);
      expect(config.compression, compression);
      expect(config.createOneImage, isTrue);
    });
  });
}
