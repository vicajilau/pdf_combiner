import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner Combine Unit Tests', () {
    late File testFile1;
    late File testFile2;
    final String testFilePath1 = 'test_1.pdf';
    final String testFilePath2 = 'test_2.pdf';
    final pdfCombiner = PdfCombiner();
    PdfCombiner.isMock = true;

    setUp(() async {
      testFile1 = File(testFilePath1);
      testFile2 = File(testFilePath2);
    });

    tearDown(() async {
      if (await testFile1.exists()) {
        await testFile1.delete();
      }

      if (await testFile2.exists()) {
        await testFile2.delete();
      }
    });

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
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path.pdf',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.success);
      expect(result.outputPath, "output/path.pdf");
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'MergeMultiplePDFResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for wrong outputPath in combining multiple PDFs using PdfCombiner.
    test('mergeMultiplePDFs wrong outputPath', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      PdfCombinerPlatform.instance = fakePlatform;

      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path.jpeg',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message,
          'The outputPath must have a .pdf format: output/path.jpeg');
      expect(result.toString(),
          'MergeMultiplePDFResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error setting a different type of file in the mergeMultiplePDF method.
    test('combine - Error empty inputPaths', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      // Call the method and check the response.
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: [],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
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
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: ['path1', 'path2'],
        outputPath: 'output/path.pdf',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(
          result.message, 'File is not of PDF type or does not exist: path1');
    });

    // Test for an incorrect platform in the mergeMultiplePDF method.
    test('combine - Error handling (Simulated Error)', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      final result = await fakePlatformWithError.mergeMultiplePDFs(
        inputPaths: ['path1', 'path2'],
        outputPath: 'output/path.pdf',
      );

      // Verify the error result matches the expected values.
      expect(result, 'error');
    });

    // Test for error handling when file does not exist in the mergeMultiplePDF method.
    test('combine - Error handling (File does not exist)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: ['path1.pdf', 'path2.pdf'],
        outputPath: 'output/path.pdf',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'File is not of PDF type or does not exist: path1.pdf');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('combine - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path.pdf',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, 'error');
      expect(result.toString(),
          'MergeMultiplePDFResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('combine - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path.pdf',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, 'Exception: Mocked Exception');
      expect(result.toString(),
          'MergeMultiplePDFResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error setting a different type of file in the mergeMultiplePDF method.
    test('combine - Error in processing', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      // Call the method and check the response.
      final result = await pdfCombiner.mergeMultiplePDFs(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path.pdf',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, "error");
      expect(result.toString(),
          'MergeMultiplePDFResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });
  });
}
