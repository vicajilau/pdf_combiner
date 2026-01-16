import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner Generate From Document Unit Tests', () {
    late File testFile1;
    final String testFilePath1 = 'document_0.pdf';
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
      expect(result, "output/path.pdf");
    });

    // Test for successfully combining multiple PDFs using PdfCombiner.
    test('generatePDFFromDocuments mix of documents (PdfCombiner)', () async {
      PdfCombiner.isMock = true;
      DocumentUtils.setTemporalFolderPath("./example/assets/temp");
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();

      // Replace the platform instance with the mock implementation.
      PdfCombinerPlatform.instance = fakePlatform;

      // Call the method and check the response.
      final result = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: [
          'example/assets/image_1.jpeg',
          'example/assets/document_1.pdf',
        ],
        outputPath: 'path.pdf',
      );

      // Verify the result matches the expected mock values.
      expect(result, "path.pdf");
    });

    // Test for error with wrong outputPath in combining multiple PDFs using PdfCombiner.

    test('error with wrong outputPath (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/image_1.jpeg',
            'example/assets/document_1.pdf',
          ],
          outputPath: 'path.jpg',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The outputPath must have a .pdf format: path.jpg',
          ),
        ),
      );
    });

    test('generatePDFFromDocuments File does not exist (PdfCombiner)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/document_5.pdf',
            'example/assets/image_1.jpeg'
          ],
          outputPath: 'path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The file is neither a PDF document nor an image or does not exist: example/assets/document_5.pdf',
          ),
        ),
      );
    });

    test('generatePDFFromDocuments File does not exist (PdfCombiner)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/document_5.pdf',
            'example/assets/image_1.jpeg'
          ],
          outputPath: 'path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The file is neither a PDF document nor an image or does not exist: example/assets/document_5.pdf',
          ),
        ),
      );
    });

    test('generatePDFFromDocuments File PDF issue (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/image_5.jpeg',
            'example/assets/image_2.png'
          ],
          outputPath: 'path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The file is neither a PDF document nor an image or does not exist: example/assets/image_5.jpeg',
          ),
        ),
      );
    });

    // Test for empty outputPath in combining multiple PDFs using PdfCombiner.

    test('generatePDFFromDocuments Empty outputPath (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/document_1.pdf',
            'example/assets/image_1.jpeg'
          ],
          outputPath: '',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The parameter (outputPath) cannot be empty',
          ),
        ),
      );
    });

    test('combine - Error empty inputPaths', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The parameter (inputPaths) cannot be empty',
          ),
        ),
      );
    });

    test('combine - Error handling (Only PDF file allowed)', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: ['path1', 'path2'],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The file is neither a PDF document nor an image or does not exist: path1',
          ),
        ),
      );
    });

    test('combine - Error handling (File does not exist)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: ['path1.pdf', 'path2.pdf'],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The file is neither a PDF document nor an image or does not exist: path1.pdf',
          ),
        ),
      );
    });

    test('combine - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/document_1.pdf',
            'example/assets/document_2.pdf'
          ],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException && e.message == 'error',
          ),
        ),
      );
    });

    test('combine - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/document_1.pdf',
            'example/assets/document_2.pdf'
          ],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException && e.message == 'Mocked Exception',
          ),
        ),
      );
    });

    test('combine - Error createPDFFromMultipleImages', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputPaths: [
            'example/assets/image_1.jpeg',
          ],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException && e.message == 'error',
          ),
        ),
      );
    });
  });
}
