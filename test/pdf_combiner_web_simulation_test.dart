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
    required List<MergeInput> inputs,
    required String outputPath,
  }) {
    return Future.value(outputPath);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    return Future.value(outputPath);
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required MergeInput input,
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
      PdfCombinerPlatform.instance = MockPdfCombinerPlatformSuccess();
    });

    tearDown(() {
      PdfCombiner.isMock = false;
    });

    test('covers web-specific path in mergeMultiplePDFs (Uint8List)', () async {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputs: [MergeInput.bytes(pdfBytes)],
        outputPath: 'output.pdf',
      );
      expect(result, 'output.pdf');
    });

    test('covers file writing path in mergeMultiplePDFs (isMock=false)',
        () async {
      PdfCombiner.isMock = false;
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);

      try {
        await PdfCombiner.mergeMultiplePDFs(
          inputs: [MergeInput.bytes(pdfBytes)],
          outputPath: 'output.pdf',
        );
      } catch (_) {}
      PdfCombiner.isMock = true;
    });
  });
}
