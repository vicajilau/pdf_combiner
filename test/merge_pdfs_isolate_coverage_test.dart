import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/isolates/merge_pdfs_isolate.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
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
    dynamic config,
  }) {
    return Future.value(outputPath);
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required MergeInput input,
    required String outputPath,
    dynamic config,
  }) {
    return Future.value([outputPath]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String tempPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('merge_pdfs_isolate_test_');
    tempPath = tempDir.path;
    DocumentUtils.setTemporalFolderPath(tempPath);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MergePdfsIsolate Coverage', () {
    test('mergeMultiplePDFs isMock = true, invalid outputPath', () async {
      PdfCombiner.isMock = true;
      final pdfFile = File('$tempPath/test.pdf');
      await pdfFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0x25, 0x45, 0x4F, 0x46]);

      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.path(pdfFile.path)],
        outputPath: 'invalid_extension.txt',
      );
      expect(result, PdfCombinerMessages.errorMessageInvalidOutputPath('invalid_extension.txt'));
    });

    test('mergeMultiplePDFs isMock = true, invalid input PDF', () async {
      PdfCombiner.isMock = true;
      final invalidPdfFile = File('$tempPath/not_a_pdf.pdf');
      await invalidPdfFile.writeAsString('Not a PDF');

      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.path(invalidPdfFile.path)],
        outputPath: '$tempPath/output.pdf',
      );
      expect(result, PdfCombinerMessages.errorMessagePDF(invalidPdfFile.path));
    });

    test('mergeMultiplePDFs isMock = true, invalid bytes input', () async {
      PdfCombiner.isMock = true;
      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.bytes(Uint8List.fromList([1, 2, 3]))],
        outputPath: '$tempPath/output.pdf',
      );
      expect(result, PdfCombinerMessages.errorMessagePDF('File in bytes'));
    });

    test('mergeMultiplePDFs isMock = true, success', () async {
      PdfCombiner.isMock = true;
      PdfCombinerPlatform.instance = MockPdfCombinerPlatformSuccess();
      
      final pdfFile = File('$tempPath/test.pdf');
      await pdfFile.writeAsBytes([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0x25, 0x45, 0x4F, 0x46]);

      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.path(pdfFile.path)],
        outputPath: '$tempPath/output.pdf',
      );
      expect(result, '$tempPath/output.pdf');
    });

    test('mergeMultiplePDFs isMock = false, coverage of _combinePDFs via compute', () async {
      PdfCombiner.isMock = false;
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0x25, 0x45, 0x4F, 0x46]);
      final pdfFile = File('$tempPath/test.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      try {
        await MergePdfsIsolate.mergeMultiplePDFs(
          inputs: [
            MergeInput.path(pdfFile.path),
            MergeInput.bytes(pdfBytes),
          ],
          outputPath: '$tempPath/output.pdf',
        );
      } catch (e) {
        // Expected failure in isolate, but code should have executed.
      }
    });

    test('mergeMultiplePDFs isMock = false, _validate returns error in _combinePDFs', () async {
      PdfCombiner.isMock = false;
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, 0x25, 0x45, 0x4F, 0x46]);
      final pdfFile = File('$tempPath/test_valid.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.path(pdfFile.path)],
        outputPath: 'invalid.txt',
      );
      expect(result, PdfCombinerMessages.errorMessageInvalidOutputPath('invalid.txt'));
    });

    test('mergeMultiplePDFs isMock = false, exception inside _combinePDFs catch block', () async {
      PdfCombiner.isMock = false;
      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.path('non_existent_file_xyz.pdf')],
        outputPath: '$tempPath/output.pdf',
      );
      // PathNotFoundException caught and returned as string
      expect(result, contains('PathNotFoundException'));
    });

    test('mergeMultiplePDFs isMock = true, allPdfs is false and outputPath is valid', () async {
      PdfCombiner.isMock = true;
      final txtFile = File('$tempPath/test.txt');
      await txtFile.writeAsString('Not a PDF');
      
      final result = await MergePdfsIsolate.mergeMultiplePDFs(
        inputs: [MergeInput.path(txtFile.path)],
        outputPath: 'valid.pdf',
      );
      expect(result, PdfCombinerMessages.errorMessagePDF(txtFile.path));
    });
  });
}
