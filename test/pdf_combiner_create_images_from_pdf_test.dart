import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner Create Images From PDF Unit Tests', () {
    PdfCombiner.isMock = true;

    test('createImageFromPDF - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createImageFromPDF(
          input: MergeInput.path('example/assets/document_1.pdf'),
          outputDirPath: 'output/path',
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException && e.message == 'error',
          ),
        ),
      );
    });

    test('createImageFromPDF - Error inside of array', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createImageFromPDF(
          input: MergeInput.path('example/assets/document_1.pdf'),
          outputDirPath: 'output/path',
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException && e.message == 'error',
          ),
        ),
      );
    });

    test('createImageFromPDF - Error with empty response', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createImageFromPDF(
          input: MergeInput.path('example/assets/document_1.pdf'),
          outputDirPath: 'output/path',
          config: ImageFromPdfConfig(
            rescale: ImageScale(width: 500, height: 200),
          ),
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException && e.message == 'Error in processing',
          ),
        ),
      );
    });

    test('createImageFromPDF - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createImageFromPDF(
          input: MergeInput.path('example/assets/document_1.pdf'),
          outputDirPath: 'output/path',
        ),
        throwsA(
          predicate(
            (e) => e is Exception,
          ),
        ),
      );
    });

    test('createImageFromPDF - success generate a single image', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final outputDirPath = 'output/path';

      final result = await PdfCombiner.createImageFromPDF(
        input: MergeInput.path('example/assets/document_1.pdf'),
        outputDirPath: outputDirPath,
        config: ImageFromPdfConfig(createOneImage: true),
      );

      expect(result, ['$outputDirPath/image1.png']);
    });

    test('createImageFromPDF - success generate multiple images', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final outputDirPath = 'output/path';

      final result = await PdfCombiner.createImageFromPDF(
        input: MergeInput.path('example/assets/document_1.pdf'),
        outputDirPath: outputDirPath,
      );

      expect(
          result, ['$outputDirPath/image1.png', '$outputDirPath/image2.png']);
    });
  });
}
