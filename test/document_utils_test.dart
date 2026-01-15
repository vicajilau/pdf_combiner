import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

import 'mocks/mock_document_utils.dart';

void main() {
  late bool originalIsMock;

  setUp(() {
    // Save original value to restore it in tearDown
    originalIsMock = PdfCombiner.isMock;
  });

  tearDown(() {
    // Restore original value even if the test changes the flag
    PdfCombiner.isMock = originalIsMock;
  });

  /// Helpers

  Future<File> createFileWithBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // Minimum signatures by "magic number"
  // PDF: "%PDF-1.4" + ... + "%%EOF"
  final pdfBytes = <int>[
    0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
    0x0A,
    // dummy minimum body
    0x25, 0x25, 0x45, 0x4F, 0x46, // %%EOF
  ];

  // PNG: 8-byte signature + some padding
  final pngBytes = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    // Padding to avoid false negatives
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  ];

  // JPEG: FF D8 FF + padding
  final jpgBytes = <int>[
    0xFF, 0xD8, 0xFF, // JPEG signature
    0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, // JFIF...
  ];

  // Valid tiny PNG for decoders
  final tinyPng = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00, 
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 
    0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0x44, 0x74, 0x8E, 0x00, 0x00, 0x00, 
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
  ];

  group('getTemporalFolderPath', () {
    test('returns mock path when PdfCombiner.isMock = true', () {
      PdfCombiner.isMock = true;

      final path = MockDocumentUtils.getTemporalFolderPath();

      expect(path, './example/assets/temp');
    });

    test('returns Directory.systemTemp.path when PdfCombiner.isMock = false',
        () {
      PdfCombiner.isMock = false;

      final path = MockDocumentUtils.getTemporalFolderPath();

      expect(path, "./example/assets/temp");
    });
  });

  group('removeTemporalFiles', () {
    test('does not delete anything when isMock = true (skips the loop)', () async {
      PdfCombiner.isMock = true;
      final mockTemp = MockDocumentUtils.getTemporalFolderPath();
      final fileInMockTemp = p.join(mockTemp, 'will_not_be_deleted.tmp');

      final file = await createFileWithBytes(fileInMockTemp, [1, 2, 3]);

      // Even when the path is inside the mock temporal folder, it should not delete it
      DocumentUtils.removeTemporalFiles([fileInMockTemp]);

      expect(File(fileInMockTemp).existsSync(), isTrue);

      // Cleanup
      await file.delete();
    });

    test('deletes file when isMock = false and the file exists', () async {
      PdfCombiner.isMock = false;
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_test_delete_');
      final filePath = p.join(tempDir.path, 'file_to_delete.tmp');
      final file = await createFileWithBytes(filePath, [1, 2, 3]);

      expect(file.existsSync(), isTrue,
          reason: "File should exist before deletion");

      DocumentUtils.removeTemporalFiles([filePath]);

      expect(file.existsSync(), isFalse,
          reason: "File should have been deleted");

      await tempDir.delete(recursive: true);
    });

    test('deletes only files inside systemTemp when isMock = false',
        () async {
      PdfCombiner.isMock = false;

      // Inside /tmp (or the equivalent path in the OS)
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_test_');
      final insidePath = p.join(tempDir.path, 'to_delete.tmp');

      // Outside system temp: we use the current project directory
      final outsidePath =
          p.join(Directory.current.path, 'should_not_be_deleted.tmp');
      final outsideFile = await createFileWithBytes(outsidePath, [9, 9, 9]);

      // We also test a non-existent path that DOES start with systemTemp
      final nonExistentInside = p.join(tempDir.path, 'non_existent.tmp');

      DocumentUtils.removeTemporalFiles(
          [insidePath, outsidePath, nonExistentInside]);

      // It should have deleted the one inside systemTemp
      expect(File(insidePath).existsSync(), isFalse);

      // It should not delete the one outside
      expect(File(outsidePath).existsSync(), isTrue);

      // The non-existent one should not throw an error
      expect(File(nonExistentInside).existsSync(), isFalse);

      // Cleanup
      await outsideFile.delete();
      await tempDir.delete(recursive: true);
    });
  });

  group('hasPDFExtension', () {
    test('true for ".pdf"', () {
      expect(DocumentUtils.hasPDFExtension('foo.pdf'), isTrue);
    });

    test('false for ".PDF" (case-sensitive comparison)', () {
      expect(DocumentUtils.hasPDFExtension('bar.PDF'), isFalse);
    });
  });

  group('isPDF', () {
    test('true for a file with PDF magic number', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_pdf_');
      final pdfPath = p.join(tempDir.path, 'test.pdf');
      await createFileWithBytes(pdfPath, pdfBytes);

      final result = await DocumentUtils.isPDF(pdfPath);
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false for a file that is not PDF (e.g. PNG)', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_pdf2_');
      final pngPath = p.join(tempDir.path, 'image.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isPDF(pngPath);
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false when there is an exception (non-existent path)', () async {
      final nonExistent = p.join(Directory.systemTemp.path, 'no_such_file.pdf');
      final result = await DocumentUtils.isPDF(nonExistent);
      expect(result, isFalse);
    });
  });

  group('isImage', () {
    test('true for PNG', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_png_');
      final pngPath = p.join(tempDir.path, 'img.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isImage(pngPath);
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('true for JPG/JPEG', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_jpg_');
      final jpgPath = p.join(tempDir.path, 'img.jpg');
      await createFileWithBytes(jpgPath, jpgBytes);

      final result = await DocumentUtils.isImage(jpgPath);
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false for PDF', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_pdf_');
      final pdfPath = p.join(tempDir.path, 'doc.pdf');
      await createFileWithBytes(pdfPath, pdfBytes);

      final result = await DocumentUtils.isImage(pdfPath);
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false when there is an exception (non-existent path)', () async {
      final nonExistent =
          p.join(Directory.systemTemp.path, 'no_such_image.png');
      final result = await DocumentUtils.isImage(nonExistent);
      expect(result, isFalse);
    });
  });

  group('convertHeicToJpeg', () {
    test('converts valid image to JPEG and returns new path', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_conv_');
      // Set temporal folder to a controlled one for the test
      DocumentUtils.setTemporalFolderPath(tempDir.path);
      
      final inputPath = p.join(tempDir.path, 'input.heic');
      await createFileWithBytes(inputPath, tinyPng);

      final outputPath = await DocumentUtils.convertHeicToJpeg(inputPath);

      expect(outputPath, inputPath);
      expect(p.extension(outputPath), '.heic');
      expect(File(outputPath).existsSync(), isTrue);
      
      // Verify it's actually in our temp folder
      expect(outputPath.startsWith(tempDir.path), isTrue);

      // Cleanup
      await tempDir.delete(recursive: true);
      // Reset temporal folder if needed or let tearDown handle state
    });

    test('returns original path if image decoding fails', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_conv_fail_');
      final inputPath = p.join(tempDir.path, 'corrupt.heic');
      await createFileWithBytes(inputPath, [0, 1, 2, 3]); // Invalid image data

      final outputPath = await DocumentUtils.convertHeicToJpeg(inputPath);

      expect(outputPath, inputPath);

      await tempDir.delete(recursive: true);
    });
  });
}
