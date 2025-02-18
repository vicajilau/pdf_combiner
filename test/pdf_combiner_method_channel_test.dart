import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';

class TestPdfCombinerPlatform extends PdfCombinerPlatform {}

void main() {
  late PdfCombinerPlatform platform;

  setUp(() {
    platform = TestPdfCombinerPlatform();
  });

  group('PdfCombinerPlatform UnimplementedError Tests', () {
    test('mergeMultiplePDFs should throw UnimplementedError', () {
      expect(
            () async => await platform.mergeMultiplePDFs(
          inputPaths: ['file1.pdf', 'file2.pdf'],
          outputPath: '/path/to/output/',
        ),
        throwsUnimplementedError,
      );
    });

    test('createPDFFromMultipleImages should throw UnimplementedError', () {
      expect(
            () async => await platform.createPDFFromMultipleImages(
          inputPaths: ['image1.jpg', 'image2.png'],
          outputPath: '/path/to/output/',
        ),
        throwsUnimplementedError,
      );
    });

    test('createImageFromPDF should throw UnimplementedError', () {
      expect(
            () async => await platform.createImageFromPDF(
          inputPath: 'file1.pdf',
          outputPath: '/path/to/output/',
        ),
        throwsUnimplementedError,
      );
    });
  });
}
