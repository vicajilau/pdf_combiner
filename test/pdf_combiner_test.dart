import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'mocks/mock_pdf_combiner_platform.dart';

// Mock platform that simulates an error in the mergeMultiplePDF method.
class MockPdfCombinerPlatformWithError extends MockPdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.error('Simulated Error');
  }
}

void main() {
  group('PdfCombiner Unit Tests', () {
    // Preserve the initial platform to reset it later if necessary.
    final PdfCombinerPlatform initialPlatform = PdfCombinerPlatform.instance;

    // Test to verify the default instance of PdfCombinerPlatform.
    test('$MethodChannelPdfCombiner is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelPdfCombiner>());
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('combine (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: ['assets/document_1.pdf', 'assets/document_2.pdf'],
        outputPath: 'output/path',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, 'Merged PDF');
      expect(result.message, 'Processed successfully');
    });

    // Test for error handling when the platform simulates a failure in the mergeMultiplePDF method.
    test('combine - Error handling (Only PDF file allowed)', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      // Call the method and check the response.
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: ['path1', 'path2'],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'Only PDF file allowed. File is not a pdf: path2');
    });

    // Test for error handling when the platform simulates a failure in the mergeMultiplePDF method.
    test('combine - Error handling (File does not exist)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: ['path1.pdf', 'path2.pdf'],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'File does not exist: path2.pdf');
    });
  });
}
