import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner  Create PDF From Multiple Images Unit Tests', () {
    PdfCombiner.isMock = true;

    test('createPDFFromMultipleImages - Error handling (empty inputPaths)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [],
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

    test('createPDFFromMultipleImages - Error handling (File is not an image)',
        () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
            MergeInput.path('example/assets/image_2.png'),
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

    test('createPDFFromMultipleImages - success generate PDF', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final outputPath = 'output/path/pdf_output.pdf';

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputs: [
          MergeInput.path('example/assets/image_1.jpeg'),
          MergeInput.path('example/assets/image_2.png'),
        ],
        outputPath: outputPath,
      );

      expect(result, outputPath);
    });

    test('createPDFFromMultipleImages wrong outputPath', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final outputPath = 'output/path/pdf_output.jpeg';

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
            MergeInput.path('example/assets/image_2.png'),
          ],
          outputPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'The outputPath must have a .pdf format: output/path/pdf_output.jpeg',
          ),
        ),
      );
    });

    test('createPDFFromMultipleImages - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
            MergeInput.path('example/assets/image_2.png'),
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

    test('createPDFFromMultipleImages - Error in processing', () async {
      MockPdfCombinerPlatformWithError fakePlatform =
          MockPdfCombinerPlatformWithError();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
            MergeInput.path('example/assets/image_2.png'),
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
