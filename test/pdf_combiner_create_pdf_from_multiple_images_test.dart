import 'dart:io';
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

    test('createPDFFromMultipleImages - Error handling (File does not exist)',
        () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [MergeInputPath('path1'), MergeInputPath('path2')],
          outputPath: 'output/path.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'File is not an image or does not exist: path1',
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
          inputs: [
            MergeInputPath('assets/document_1.pdf'),
            MergeInputPath('path2.jpg')
          ],
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
          inputs: [
            MergeInputPath('example/assets/image_1.jpeg'),
            MergeInputPath('example/assets/image_2.png')
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
      PdfCombinerPlatform.instance = fakePlatform;

      final image1 = File('image_1.png');
      await image1
          .writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final image2 = File('image_2.jpg');
      await image2.writeAsBytes([0xFF, 0xD8, 0xFF]);

      final outputPath = 'output/path/pdf_output.pdf';

      try {
        final result = await PdfCombiner.createPDFFromMultipleImages(
          inputs: [MergeInputPath(image1.path), MergeInputPath(image2.path)],
          outputPath: outputPath,
        );

        expect(result, outputPath);
      } finally {
        if (await image1.exists()) await image1.delete();
        if (await image2.exists()) await image2.delete();
      }
    });

    // Test for error handling when you try to send a file that its not a pdf in createPDFFromMultipleImages

    test('createPDFFromMultipleImages wrong outputPath', () async {
      MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
      PdfCombinerPlatform.instance = fakePlatform;

      final outputPath = 'output/path/pdf_output.jpeg';

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [
            MergeInputPath('example/assets/image_1.jpeg'),
            MergeInputPath('example/assets/image_2.png')
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
            MergeInputPath('example/assets/image_1.jpeg'),
            MergeInputPath('example/assets/image_2.png')
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
          inputs: [
            MergeInputPath('example/assets/image_1.jpeg'),
            MergeInputPath('example/assets/image_2.png')
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
          inputs: [
            MergeInputPath('example/assets/image_1.jpeg'),
            MergeInputPath('example/assets/image_2.png')
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
