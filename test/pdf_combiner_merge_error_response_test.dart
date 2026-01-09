import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'dart:io' as java;

class MockPdfCombinerPlatformCustomError
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  final String errorMessage;

  MockPdfCombinerPlatformCustomError(this.errorMessage);

  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.value(errorMessage);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    return Future.value(errorMessage);
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    return Future.value([errorMessage]);
  }
}

class MockPdfCombinerPlatformNullResponse
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.value(null);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    return Future.value(null);
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    return Future.value(null);
  }
}

void main() {
  group('PdfCombiner Error Handling', () {
    setUp(() {
      PdfCombiner.isMock = true;
    });

    group('mergeMultiplePDFs', () {
      test('returns error message when platform returns a custom error string',
          () async {
        const customError = 'Custom platform error';
        final mockPlatform = MockPdfCombinerPlatformCustomError(customError);
        PdfCombinerPlatform.instance = mockPlatform;

        final file1 = await java.File('test_pdf_C.pdf').create();
        await file1.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
        final file2 = await java.File('test_pdf_D.pdf').create();
        await file2.writeAsBytes([0x25, 0x50, 0x44, 0x46]);

        try {
          expect(
            () async => await PdfCombiner.mergeMultiplePDFs(
              inputPaths: ['test_pdf_C.pdf', 'test_pdf_D.pdf'],
              outputPath: 'output.pdf',
            ),
            throwsA(isA<PdfCombinerException>()),
          );
        } finally {
          if (await file1.exists()) await file1.delete();
          if (await file2.exists()) await file2.delete();
        }
      });

      test('returns default error message when platform returns null',
          () async {
        final mockPlatform = MockPdfCombinerPlatformNullResponse();
        PdfCombinerPlatform.instance = mockPlatform;

        final file1 = await java.File('test_pdf_A.pdf').create();
        await file1.writeAsBytes([0x25, 0x50, 0x44, 0x46]);
        final file2 = await java.File('test_pdf_B.pdf').create();
        await file2.writeAsBytes([0x25, 0x50, 0x44, 0x46]);

        try {
          expect(
            () async => await PdfCombiner.mergeMultiplePDFs(
              inputPaths: ['test_pdf_A.pdf', 'test_pdf_B.pdf'],
              outputPath: 'output.pdf',
            ),
            throwsA(isA<PdfCombinerException>()),
          );
        } finally {
          if (await file1.exists()) await file1.delete();
          if (await file2.exists()) await file2.delete();
        }
      });
    });

    group('createPDFFromMultipleImages', () {
      test('throws exception when platform returns a custom error string',
          () async {
        const customError = 'Custom platform error';
        final mockPlatform = MockPdfCombinerPlatformCustomError(customError);
        PdfCombinerPlatform.instance = mockPlatform;

        final file1 = await java.File('image1.png').create();
        // PNG magic number: 89 50 4E 47 0D 0A 1A 0A
        await file1
            .writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

        try {
          expect(
            () async => await PdfCombiner.createPDFFromMultipleImages(
              inputPaths: ['image1.png'],
              outputPath: 'output_images.pdf',
            ),
            throwsA(isA<PdfCombinerException>()
                .having((e) => e.message, 'message', customError)),
          );
        } finally {
          if (await file1.exists()) await file1.delete();
        }
      });

      test('throws default exception when platform returns null', () async {
        final mockPlatform = MockPdfCombinerPlatformNullResponse();
        PdfCombinerPlatform.instance = mockPlatform;

        final file1 = await java.File('image_null.png').create();
        await file1
            .writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

        try {
          expect(
            () async => await PdfCombiner.createPDFFromMultipleImages(
              inputPaths: ['image_null.png'],
              outputPath: 'output_images.pdf',
            ),
            throwsA(isA<PdfCombinerException>().having(
                (e) => e.message, 'message', PdfCombinerMessages.errorMessage)),
          );
        } finally {
          if (await file1.exists()) await file1.delete();
        }
      });
    });

    group('createImageFromPDF', () {
      test(
          'throws exception when platform returns a list containing an error string',
          () async {
        const customError = 'Custom platform error';
        final mockPlatform = MockPdfCombinerPlatformCustomError(customError);
        PdfCombinerPlatform.instance = mockPlatform;

        final file1 = await java.File('input.pdf').create();
        await file1.writeAsBytes([0x25, 0x50, 0x44, 0x46]);

        try {
          expect(
            () async => await PdfCombiner.createImageFromPDF(
              inputPath: 'input.pdf',
              outputDirPath: 'output_dir',
            ),
            throwsA(isA<PdfCombinerException>()
                .having((e) => e.message, 'message', customError)),
          );
        } finally {
          if (await file1.exists()) await file1.delete();
        }
      });
    });
  });
}
