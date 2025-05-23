import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/pdf_combiner_delegate.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner Create Images From PDF Unit Tests', () {
    PdfCombiner.isMock = true;
    // Test for error handling when you try to send a file that its not a pdf in createImageFromPDF
    test('createImageFromPDF - Error handling (File is not a pdf)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'assets/test_image1.png',
        outputDirPath: 'output/path',
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(),
              'Exception: File is not of PDF type or does not exist: assets/test_image1.png');
        }),
      );

      // Verify the error result matches the expected values.
      expect(result.outputPaths, []);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'File is not of PDF type or does not exist: assets/test_image1.png');
    });

    // Test for error handling when you try to send a file that file not exist in createImageFromPDF
    test('createImageFromPDF - Error handling (File not exist)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'assets/test_image_not_exist.pdf',
        outputDirPath: 'output/path',
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(),
              'Exception: File is not of PDF type or does not exist: assets/test_image_not_exist.pdf');
        }),
      );

      // Verify the error result matches the expected values.
      expect(result.outputPaths, []);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'File is not of PDF type or does not exist: assets/test_image_not_exist.pdf');
    });

    // Test for error handling when you try to send a file that its not a pdf in createImageFromPDF
    test('createImageFromPDF - Error handling (empty inputPath)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: '',
        outputDirPath: 'output/path',
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(),
              'Exception: The parameter (inputPath) cannot be empty');
        }),
      );

      // Verify the error result matches the expected values.
      expect(result.outputPaths, []);
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, 'The parameter (inputPath) cannot be empty');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('createImageFromPDF - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputDirPath: 'output/path',
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(), 'Exception: error');
        }),
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPaths, []);
      expect(result.message, 'error');
      expect(result.toString(),
          'ImageFromPDFResponse{outputPaths: ${result.outputPaths}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('createImageFromPDF - Error inside of array', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputDirPath: 'output/path',
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(), 'Exception: error');
        }),
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPaths, []);
      expect(result.message, 'error');
      expect(result.toString(),
          'ImageFromPDFResponse{outputPaths: ${result.outputPaths}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('createImageFromPDF - Error with empty response', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputDirPath: 'output/path',
        config: ImageFromPdfConfig(
          rescale: ImageScale(width: 500, height: 200),
        ),
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(), 'Exception: Error in processing');
        }),
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPaths, []);
      expect(result.message, 'Error in processing');
      expect(result.toString(),
          'ImageFromPDFResponse{outputPaths: ${result.outputPaths}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for Mocked Exception creating image form PDF using PdfCombiner.
    test('createImageFromPDF - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputDirPath: 'output/path',
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          fail("Test failed due to success: $paths");
        }, onError: (error) {
          expect(error.toString(), 'Exception: Mocked Exception');
        }),
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPaths, []);
      expect(result.message, 'Exception: Mocked Exception');
      expect(result.toString(),
          'ImageFromPDFResponse{outputPaths: ${result.outputPaths}, message: ${result.message}, status: ${result.status} }');
    });

    // Test successfully for createImageFromPDF
    test('createImageFromPDF - success generate a single image', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      final outputDirPath = 'output/path';

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputDirPath: outputDirPath,
        config: ImageFromPdfConfig(createOneImage: true),
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          expect(paths, ['$outputDirPath/image1.png']);
        }, onError: (error) {
          fail("Test failed due to error: ${error.toString()}");
        }),
      );

      // Verify the error result matches the expected values.
      expect(result.outputPaths, ['$outputDirPath/image1.png']);
      expect(result.status, PdfCombinerStatus.success);
      expect(result.message, null);
      expect(result.toString(),
          'ImageFromPDFResponse{outputPaths: ${result.outputPaths}, message: ${result.message}, status: ${result.status} }');
    });

    // Test successfully for createImageFromPDF
    test('createImageFromPDF - success generate multiple images', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      final outputDirPath = 'output/path';

      // Call the method and check the response.
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'example/assets/document_1.pdf',
        outputDirPath: outputDirPath,
        delegate: PdfCombinerDelegate(onSuccess: (paths) {
          expect(paths,
              ['$outputDirPath/image1.png', '$outputDirPath/image2.png']);
        }, onError: (error) {
          fail("Test failed due to error: ${error.toString()}");
        }),
      );

      // Verify the error result matches the expected values.
      expect(result.outputPaths,
          ['$outputDirPath/image1.png', '$outputDirPath/image2.png']);
      expect(result.status, PdfCombinerStatus.success);
      expect(result.message, null);
      expect(result.toString(),
          'ImageFromPDFResponse{outputPaths: ${result.outputPaths}, message: ${result.message}, status: ${result.status} }');
    });
  });
}
