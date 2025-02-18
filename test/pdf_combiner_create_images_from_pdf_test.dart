import 'package:flutter_test/flutter_test.dart';
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
  group('PdfCombiner Create Images From PDF Unit Tests', () {
    // Test for error handling when you try to send a file that its not a pdf in createImageFromPDF
    test('createImageFromPDF - Error handling (File is not a pdf)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'assets/test_image1.png',
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'Only PDF file allowed. File is not a pdf: assets/test_image1.png');
    });

    // Test for error handling when you try to send a file that its not a pdf in createImageFromPDF
    test('createImageFromPDF - Error handling (empty inputPath)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: '',
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'The parameter (inputPath) cannot be empty');
    });

    // Test successfully for createImageFromPDF
    test('createImageFromPDF - success generate images', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.response, ['image1.png']);
      expect(result.status, PdfCombinerStatus.success);
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'ImageFromPDFResponse{response: ${result.response}, message: ${result.message}, status: ${result.status} }');
    });
  });
}
