import 'dart:io';

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
  group('PdfCombiner Combine Unit Tests', () {
    late File testFile1;
    late File testFile2;
    final String testFilePath1 = 'test_1.pdf';
    final String testFilePath2 = 'test_2.pdf';
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
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputs: [
          MergeInput.path('example/assets/document_1.pdf'),
          MergeInput.path('example/assets/document_2.pdf'),
        ],
        outputPath: 'output/path.pdf',
      );

      // Verify the result matches the expected mock values.
      expect(result, "output/path.pdf");
    });

    // Test for wrong outputPath in combining multiple PDFs using PdfCombiner.

    test('mergeMultiplePDFs wrong outputPath', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
          inputs: [
            MergeInput.path('example/assets/document_1.pdf'),
            MergeInput.path('example/assets/document_2.pdf'),
          ],
          outputPath: 'output/path.jpeg',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The outputPath must have a .pdf format: output/path.jpeg',
          ),
        ),
      );
    });

    test('combine - Error empty inputPaths', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
          inputs: [],
          outputPath: 'output/path',
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

    test('combine - Error handling (Simulated Error)', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();

      expect(
        () => fakePlatformWithError.mergeMultiplePDFs(
          inputs: [
            MergeInput.path('path1'),
            MergeInput.path('path2'),
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

    test('combine - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
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
        () => PdfCombiner.mergeMultiplePDFs(
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

    test('combine - Error in processing (duplicate case)', () async {
      MockPdfCombinerPlatformWithError fakePlatformWithError =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatformWithError;

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
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
  });
}
