import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner Generate From Document Unit Tests', () {
    late File testFile1;
    final String testFilePath1 = 'output_path.pdf';
    PdfCombiner.isMock = true;

    setUp(() async {
      testFile1 = File(testFilePath1);
      await testFile1.writeAsBytes(Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
      ]));
    });

    tearDown(() async {
      if (await testFile1.exists()) {
        await testFile1.delete();
      }
    });

    // Preserve the initial platform to reset it later if necessary.
    final PdfCombinerPlatform initialPlatform = PdfCombinerPlatform.instance;

    // Test to verify the default instance of PdfCombinerPlatform.
    test('$MethodChannelPdfCombiner is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelPdfCombiner>());
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments only pdfs (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
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
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments mix of documents (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/image_1.jpeg',
          'example/assets/document_1.pdf',
        ],
        outputPath: 'output_path.pdf',
      );
      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.success);
      expect(result.outputPath, "output_path.pdf");
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments File does not exist (PdfCombiner)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/image_1.jpeg'
        ],
        outputPath: 'output-path.pdf',
      );
      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message,
          'File is not of PDF type or does not exist: output-path.pdf');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments File does not exist (PdfCombiner)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/image_1.jpeg'
        ],
        outputPath: 'output-path.pdf',
      );
      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message,
          'File is not of PDF type or does not exist: output-path.pdf');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments File PDF issue (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/image_1.jpeg',
          'example/assets/image_2.png'
        ],
        outputPath: 'output-path.pdf',
      );
      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message,
          'File is not of PDF type or does not exist: output-path.pdf');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for empty outputPath in combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments Empty outputPath (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/image_1.jpeg'
        ],
        outputPath: '',
      );
      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, 'The parameter (outputPath) cannot be empty');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error setting a different type of file in the mergeMultiplePDF method.
    test('combine - Error empty inputPaths', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
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
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: ['path1', 'path2'],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'The file is neither a PDF document nor an image or does not exist: path1');
    });

    // Test for error handling when file does not exist in the mergeMultiplePDF method.
    test('combine - Error handling (File does not exist)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: ['path1.pdf', 'path2.pdf'],
        outputPath: 'output/path',
      );

      // Verify the error result matches the expected values.
      expect(result.outputPath, "");
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          'The file is neither a PDF document nor an image or does not exist: path1.pdf');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('combine - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, 'error');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error processing when combining multiple PDFs using PdfCombiner.
    test('combine - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/document_1.pdf',
          'example/assets/document_2.pdf'
        ],
        outputPath: 'output/path',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, 'Exception: Mocked Exception');
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });

    // Test for error setting a different type of file in the mergeMultiplePDF method.
    test('combine - Error createPDFFromMultipleImages', () async {
      // Create a mock platform that simulates an error during PDF merging.
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      // Replace the platform instance with the error mock implementation.
      PdfCombinerPlatform.instance = fakePlatformWithError;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/image_1.jpeg',
        ],
        outputPath: 'output/path',
      );

      // Verify the result matches the expected mock values.
      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, "error");
      expect(result.toString(),
          'GeneratePdfFromDocumentsResponse{outputPath: ${result.outputPath}, message: ${result.message}, status: ${result.status} }');
    });
  });
}
