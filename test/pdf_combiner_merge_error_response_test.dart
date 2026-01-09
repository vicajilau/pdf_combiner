import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io' as java;

class MockPdfCombinerPlatformCustomError
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  final String errorMessage;

  MockPdfCombinerPlatformCustomError(this.errorMessage);

  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.value(errorMessage);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    throw UnimplementedError();
  }
}

// Mock platform that returns null
class MockPdfCombinerPlatformNullResponse
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.value(null);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('PdfCombiner.mergeMultiplePDFs Error Handling', () {
    setUp(() {
      PdfCombiner.isMock = true;
    });

    test('returns error message when platform returns a custom error string',
        () async {
      const customError = 'Custom platform error';
      final mockPlatform = MockPdfCombinerPlatformCustomError(customError);
      PdfCombinerPlatform.instance = mockPlatform;

      final file1 = await java.File('test_doc_1.pdf').create();
      await file1.writeAsString('%PDF-1.4');
      final file2 = await java.File('test_doc_2.pdf').create();
      await file2.writeAsString('%PDF-1.4');

      try {
        final result = await PdfCombiner.mergeMultiplePDFs(
          inputPaths: ['test_doc_1.pdf', 'test_doc_2.pdf'],
          outputPath: 'output.pdf',
        );

        expect(result.message, customError);
      } finally {
        if (await file1.exists()) await file1.delete();
        if (await file2.exists()) await file2.delete();
      }
    });

    test('returns default error message when platform returns null', () async {
      final mockPlatform = MockPdfCombinerPlatformNullResponse();
      PdfCombinerPlatform.instance = mockPlatform;

      final file1 = await java.File('test_doc_null_1.pdf').create();
      await file1.writeAsString('%PDF-1.4');
      final file2 = await java.File('test_doc_null_2.pdf').create();
      await file2.writeAsString('%PDF-1.4');

      try {
        final result = await PdfCombiner.mergeMultiplePDFs(
          inputPaths: ['test_doc_null_1.pdf', 'test_doc_null_2.pdf'],
          outputPath: 'output.pdf', // Must end in .pdf
        );

        expect(result.message, PdfCombinerMessages.errorMessage);
      } finally {
        if (await file1.exists()) await file1.delete();
        if (await file2.exists()) await file2.delete();
      }
    });
  });
}
