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
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, 'Merged PDF');
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'MergeMultiplePDFResponse{response: ${result.response}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error setting a different type of file in the mergeMultiplePDF method.
    test('combine - Error empty inputPaths', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      // Call the method and check the response.
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: [],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    // Test for error setting a different type of file in the mergeMultiplePDF method.
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
      expect(result.message, 'Only PDF file allowed. File is not a pdf: path1');
    });

    // Test for an incorrect platform in the mergeMultiplePDF method.
    test('combine - Error handling (Simulated Error)', () async {
      String error = "";
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      try {
        // Call the method and check the response.
        await fakePlatformWithError.mergeMultiplePDFs(
          inputPaths: ['path1', 'path2'],
          outputPath: 'output/path',
        );
      } catch (e) {
        error = e.toString();
      }

      // Verify the error result matches the expected values.
      expect(error, 'Simulated Error');
    });

    // Test for error handling when file does not exist in the mergeMultiplePDF method.
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
      expect(result.message, 'File does not exist: path1.pdf');
    });

    ///CREATE_PDF_FROM_MULTIPLE_IMAGES

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
      expect(result.response, null);
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
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'File does not exist: path1.jpg');
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
      expect(result.response, null);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'Only Image file allowed. File is not an image: assets/document_1.pdf');
    });

    // Test for success process in createPDFFromMultipleImages
    test('createPDFFromMultipleImages - success generate PDF', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

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
      expect(result.response, 'Created PDF from Images');
      expect(result.status, PdfCombinerStatus.success);
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'PdfFromMultipleImageResponse{response: ${result.response}, message: ${result.message}, status: ${result.status} }');
    });

    ///CREATE_IMAGES_FROM_PDF

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

    // Test succesfully for createImageFromPDF
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
