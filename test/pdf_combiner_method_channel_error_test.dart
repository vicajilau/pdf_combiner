import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/models/merge_input.dart';

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
          inputs: [
            MergeInput.path('path/to/pdf1.pdf'),
            MergeInput.path('path/to/pdf2.pdf'),
          ],
          outputPath: 'path/to/output.pdf',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('createPDFFromMultipleImages throws UnimplementedError', () async {
      expect(
        () async => await PdfCombinerPlatform.instance
            .createPDFFromMultipleImages(inputs: [
          MergeInput.path('path/to/image1.png'),
          MergeInput.path('path/to/image2.png'),
        ], outputPath: 'path/to/output.pdf'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('createImageFromPDF throws UnimplementedError', () async {
      expect(
        () async => await PdfCombinerPlatform.instance.createImageFromPDF(
          input: MergeInput.path('path/to/pdf.pdf'),
          outputPath: 'path/to/output/images',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
