import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdfCombinerPlatformSuccess
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) {
    return Future.value(outputPath);
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
    return outputPath;
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required MergeInput input,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    return Future.value(['$outputPath/image1.png']);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pdf generation Tests', () {
    late Directory tempDir;
    late String tempPath;

    setUp(() async {
      PdfCombiner.isMock = true;
      tempDir = await Directory.systemTemp.createTemp('pdf_combiner_test_');
      tempPath = tempDir.path;
      DocumentUtils.setTemporalFolderPath(tempPath);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('generatePDFFromDocuments', () {
      test('throws error when file is neither PDF nor image', () async {
        final txtFile = File('$tempPath/test.txt');
        await txtFile.writeAsString('This is a text file');

        expect(
          () => PdfCombiner.generatePDFFromDocuments(
            inputs: [MergeInput.path(txtFile.path)],
            outputPath: '$tempPath/output.pdf',
          ),
          throwsA(
            predicate(
              (e) =>
                  e is PdfCombinerException &&
                  e.message.contains(
                      'The file is neither a PDF document nor an image or does not exist'),
            ),
          ),
        );
      });

      test('processes image and converts to PDF', () async {
        final mockPlatform = MockPdfCombinerPlatformSuccess();
        PdfCombinerPlatform.instance = mockPlatform;

        final result = await PdfCombiner.generatePDFFromDocuments(
          inputs: [
            MergeInput.path('example/assets/image_1.jpeg'),
            MergeInput.path('example/assets/document_1.pdf'),
          ],
          outputPath: '$tempPath/output.pdf',
        );

        expect(result, '$tempPath/output.pdf');
      });
    });

    group('mergeMultiplePDFs', () {
      test('throws error when file exists but is not PDF', () async {
        final txtFile = File('$tempPath/not_a_pdf.pdf');
        await txtFile.writeAsString('This is not a PDF');

        expect(
          () => PdfCombiner.mergeMultiplePDFs(
            inputs: [MergeInput.path(txtFile.path)],
            outputPath: '$tempPath/output.pdf',
          ),
          throwsA(
            predicate(
              (e) =>
                  e is PdfCombinerException &&
                  e.message
                      .contains('File is not of PDF type or does not exist'),
            ),
          ),
        );
      });

      test('handles temporal files', () async {
        final mockPlatform = MockPdfCombinerPlatformSuccess();
        PdfCombinerPlatform.instance = mockPlatform;

        final pdfBytes = Uint8List.fromList([
          0x25,
          0x50,
          0x44,
          0x46,
          0x2D,
          0x31,
          0x2E,
          0x34,
        ]);

        final result = await PdfCombiner.mergeMultiplePDFs(
          inputs: [MergeInput.bytes(pdfBytes)],
          outputPath: '$tempPath/output.pdf',
        );

        expect(result, '$tempPath/output.pdf');
      });
    });

    group('createPDFFromMultipleImages', () {
      test('throws error when file exists but is not image', () async {
        final txtFile = File('$tempPath/not_an_image.jpg');
        await txtFile.writeAsString('This is not an image');

        expect(
          () => PdfCombiner.createPDFFromMultipleImages(
            inputs: [MergeInput.path(txtFile.path)],
            outputPath: '$tempPath/output.pdf',
          ),
          throwsA(
            predicate(
              (e) =>
                  e is PdfCombinerException &&
                  e.message.contains('File is not an image or does not exist'),
            ),
          ),
        );
      });

      test('handles temporal files', () async {
        final mockPlatform = MockPdfCombinerPlatformSuccess();
        PdfCombinerPlatform.instance = mockPlatform;

        final pngBytes = Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);

        final result = await PdfCombiner.createPDFFromMultipleImages(
          inputs: [MergeInput.bytes(pngBytes)],
          outputPath: '$tempPath/output.pdf',
        );

        expect(result, '$tempPath/output.pdf');
      });
    });

    group('createImageFromPDF', () {
      test('throws error when file exists but is not PDF', () async {
        final txtFile = File('$tempPath/not_a_pdf.pdf');
        await txtFile.writeAsString('This is not a PDF');

        expect(
          () => PdfCombiner.createImageFromPDF(
            input: MergeInput.path(txtFile.path),
            outputDirPath: tempPath,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is PdfCombinerException &&
                  e.message
                      .contains('File is not of PDF type or does not exist'),
            ),
          ),
        );
      });

      test('throws error for bytes input that is not PDF', () async {
        final notPdfBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

        expect(
          () => PdfCombiner.createImageFromPDF(
            input: MergeInput.bytes(notPdfBytes),
            outputDirPath: tempPath,
          ),
          throwsA(
            predicate(
              (e) =>
                  e is PdfCombinerException &&
                  e.message.contains('File in bytes'),
            ),
          ),
        );
      });

      test('handles temporal files cleanup', () async {
        final mockPlatform = MockPdfCombinerPlatformSuccess();
        PdfCombinerPlatform.instance = mockPlatform;

        final pdfBytes = Uint8List.fromList([
          0x25,
          0x50,
          0x44,
          0x46,
          0x2D,
          0x31,
          0x2E,
          0x34,
        ]);

        final result = await PdfCombiner.createImageFromPDF(
          input: MergeInput.bytes(pdfBytes),
          outputDirPath: tempPath,
        );

        expect(result, ['$tempPath/image1.png']);
      });
    });

    group('DocumentUtils.prepareInput', () {
      test('creates temp directory if not exists', () async {
        final nonExistentPath = '$tempPath/non_existent_dir';
        DocumentUtils.setTemporalFolderPath(nonExistentPath);

        final pngBytes = Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);

        final result =
            await DocumentUtils.prepareInput(MergeInput.bytes(pngBytes));

        expect(result.startsWith(nonExistentPath), isTrue);
        expect(Directory(nonExistentPath).existsSync(), isTrue);

        await Directory(nonExistentPath).delete(recursive: true);
      });
    });
  });
}
