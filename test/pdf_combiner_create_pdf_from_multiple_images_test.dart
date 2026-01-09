import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import 'mocks/mock_pdf_combiner_platform.dart';
import 'mocks/mock_pdf_combiner_platform_with_error.dart';
import 'mocks/mock_pdf_combiner_platform_with_exception.dart';

void main() {
  group('PdfCombiner  Create PDF From Multiple Images Unit Tests', () {
    PdfCombiner.isMock = true;

    // Test for error handling when file not exist in the createPDFFromMultipleImages method.
    test('createPDFFromMultipleImages - Error handling (empty inputPaths)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
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

    test('createPDFFromMultipleImages - Error handling (File does not exist)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: ['path1.jpg', 'path2.jpg'],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'File is not an image or does not exist: path1.jpg',
          ),
        ),
      );
    });

    test('createPDFFromMultipleImages - Error handling (File is not an image)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: ['assets/document_1.pdf', 'path2.jpg'],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'File is not an image or does not exist: assets/document_1.pdf',
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
          inputPaths: [
            'example/assets/image_1.jpeg',
            'example/assets/image_2.png'
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
      expect(result.message, 'Processed successfully');
      expect(result.toString(),
          'PdfFromMultipleImageResponse{outputPath: ${result.outputPath}, message: ${result.message}}');
    });

    // Test for error handling when you try to send a file that its not a pdf in createPDFFromMultipleImages

    test('createPDFFromMultipleImages wrong outputPath', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final outputPath = 'output/path/pdf_output.jpeg';

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: [
            'example/assets/image_1.jpeg',
            'example/assets/image_2.png'
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
          inputPaths: [
            'example/assets/image_1.jpeg',
            'example/assets/image_2.png'
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

    test('createPDFFromMultipleImages - Mocked Exception', () async {
      MockPdfCombinerPlatformWithException fakePlatform =
          MockPdfCombinerPlatformWithException();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: [
            'example/assets/image_1.jpeg',
            'example/assets/image_2.png'
          ],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) => e is PdfCombinerException,
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
          inputPaths: [
            'example/assets/image_1.jpeg',
            'example/assets/image_2.png'
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
