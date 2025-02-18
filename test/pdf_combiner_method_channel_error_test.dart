import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';

class MockPdfCombinerPlatform extends PdfCombinerPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfCombinerPlatform Unimplemented Errors', () {
    setUp(() {
      PdfCombinerPlatform.instance = MockPdfCombinerPlatform();
    });

    test('mergeMultiplePDFs throws UnimplementedError', () async {
      expect(
        () async => await PdfCombinerPlatform.instance.mergeMultiplePDFs(
          inputPaths: ['path/to/pdf1.pdf', 'path/to/pdf2.pdf'],
          outputPath: 'path/to/output.pdf',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('createPDFFromMultipleImages throws UnimplementedError', () async {
      expect(
        () async =>
            await PdfCombinerPlatform.instance.createPDFFromMultipleImages(
          inputPaths: ['path/to/image1.png', 'path/to/image2.png'],
          outputPath: 'path/to/output.pdf',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('createImageFromPDF throws UnimplementedError', () async {
      expect(
        () async => await PdfCombinerPlatform.instance.createImageFromPDF(
          inputPath: 'path/to/pdf.pdf',
          outputPath: 'path/to/output/images',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
