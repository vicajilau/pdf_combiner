import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

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

    final PdfCombinerPlatform initialPlatform = PdfCombinerPlatform.instance;

    test('$MethodChannelPdfCombiner is the default instance', () {
      expect(initialPlatform, isInstanceOf<MethodChannelPdfCombiner>());
    });

    test('generatePDFFromDocuments only pdfs (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final result = await PdfCombiner.generatePDFFromDocuments(
        inputs: [
          MergeInput.path('example/assets/document_1.pdf'),
          MergeInput.path('example/assets/document_2.pdf'),
        ],
        outputPath: 'output/path.pdf',
      );

      expect(result, "output/path.pdf");
    });

    test('error with wrong outputPath (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
            MergeInput.path('example/assets/document_1.pdf'),
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

    test('generatePDFFromDocuments Empty outputPath (PdfCombiner)', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: [
            MergeInput.path('example/assets/document_1.pdf'),
            MergeInput.path('example/assets/image_1.jpeg'),
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

    test('combine - Error empty inputs', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      expect(
        () => PdfCombiner.generatePDFFromDocuments(
          inputs: [],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The parameter (inputs) cannot be empty',
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
          inputs: [
            MergeInput.path('example/assets/document_1.pdf'),
            MergeInput.path('example/assets/document_2.pdf'),
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
          inputs: [
            MergeInput.path('example/assets/document_1.pdf'),
            MergeInput.path('example/assets/document_2.pdf'),
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
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
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
