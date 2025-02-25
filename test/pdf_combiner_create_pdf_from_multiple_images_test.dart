import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner  Create PDF From Multiple Images Unit Tests', () {
    // Test for error handling when file not exist in the createPDFFromMultipleImages method.
    test('createPDFFromMultipleImages - Error handling (empty inputPaths)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    // Test for error handling when file not exist in the createPDFFromMultipleImages method.
    test('createPDFFromMultipleImages - Error handling (File does not exist)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: ['path1.jpg', 'path2.jpg'],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(
          result.message, 'File is not an image or does not exist: path1.jpg');
    });

    // Test for error handling when you try to send a file that its not an image in createPDFFromMultipleImages
    test('createPDFFromMultipleImages - Error handling (File is not an image)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: ['assets/document_1.pdf', 'path2.jpg'],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'File is not an image or does not exist: assets/document_1.pdf');
    });

    // Test for error handling when you try to send a file that its not an image in createPDFFromMultipleImages
    test('createPDFFromMultipleImages - Error handling (File is not an image)',
        () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [
          'example/assets/image_1.jpeg',
          'example/assets/image_2.png'
        ],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'error');
    });

    // Test for success process in createPDFFromMultipleImages
    test('createPDFFromMultipleImages - success generate PDF', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      final outputPath = 'output/path/pdf_output.pdf';

      // Call the method and check the response.
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [
          'example/assets/image_1.jpeg',
          'example/assets/image_2.png'
        ],
        outputPath: outputPath,
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, outputPath);
      expect(result.status, PdfCombinerStatus.success);
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'PdfFromMultipleImageResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });
  });

  // Test for error processing when creating pdf from multiple images using PdfCombiner.
  test('createPDFFromMultipleImages - Mocked Exception', () async {
    MockPdfCombinerPlatformWithException fakePlatform =
        MockPdfCombinerPlatformWithException();

    // Replace the platform instance with the mock implementation.
    PdfCombinerPlatform.instance = fakePlatform;

    // Call the method and check the response.
    final result = await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: ['example/assets/image_1.jpeg', 'example/assets/image_2.png'],
      outputPath: 'output/path',
    );

    // Verify the result matches the expected mock values.
    expect(result.status, PdfCombinerStatus.error);
    expect(result.outputPath, "");
    expect(result.message, 'Exception: Mocked Exception');
    expect(result.toString(),
        'PdfFromMultipleImageResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
  });

  // Test for error Mocked Exception when creating pdf from multiple images using PdfCombiner.
  test('createPDFFromMultipleImages - Mocked Exception', () async {
    MockPdfCombinerPlatformWithException fakePlatform =
        MockPdfCombinerPlatformWithException();

    // Replace the platform instance with the mock implementation.
    PdfCombinerPlatform.instance = fakePlatform;

    // Call the method and check the response.
    final result = await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: ['example/assets/image_1.jpeg', 'example/assets/image_2.png'],
      outputPath: 'output/path',
    );

    // Verify the result matches the expected mock values.
    expect(result.status, PdfCombinerStatus.error);
    expect(result.outputPath, "");
    expect(result.message, 'Exception: Mocked Exception');
    expect(result.toString(),
        'PdfFromMultipleImageResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
  });

  // Test for error processing when creating pdf from multiple images using PdfCombiner.
  test('createPDFFromMultipleImages - Error in processing', () async {
    MockPdfCombinerPlatformWithError fakePlatform =
        MockPdfCombinerPlatformWithError();

    // Replace the platform instance with the mock implementation.
    PdfCombinerPlatform.instance = fakePlatform;

    // Call the method and check the response.
    final result = await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: ['example/assets/image_1.jpeg', 'example/assets/image_2.png'],
      outputPath: 'output/path',
    );

    // Verify the result matches the expected mock values.
    expect(result.status, PdfCombinerStatus.error);
    expect(result.outputPath, "");
    expect(result.message, 'error');
    expect(result.toString(),
        'PdfFromMultipleImageResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
  });
}
