import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';

class MockPdfCombinerPlatformSuccess
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDFs({
    List<String>? inputPaths,
    required String outputPath,
  }) {
    return Future.value(outputPath);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    return Future.value(outputPath);
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    return Future.value([outputPath]);
  }
}

void main() {
  group('PdfCombiner Web Simulation Tests', () {
    setUp(() {
      PdfCombiner.isMock = true;
      PdfCombiner.isMockWeb = true;
      PdfCombinerPlatform.instance = MockPdfCombinerPlatformSuccess();
    });

    tearDown(() {
      PdfCombiner.isMock = false;
      PdfCombiner.isMockWeb = false;
    });

    test('covers web-specific path in mergeMultiplePDFs (Uint8List)', () async {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputs: [pdfBytes],
        outputPath: 'output.pdf',
      );
      expect(result, 'output.pdf');
    });

    test(
        'covers web-specific path in generatePDFFromDocuments (Uint8List image)',
        () async {
      final imageBytes =
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputs: [imageBytes],
        outputPath: 'output.pdf',
      );
      expect(result, 'output.pdf');
    });
  });
}
