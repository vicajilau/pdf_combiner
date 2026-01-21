import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

import 'mocks/mock_document_utils.dart';

void main() {
  late bool originalIsMock;

  setUp(() {
    originalIsMock = PdfCombiner.isMock;
  });

  tearDown(() {
    PdfCombiner.isMock = originalIsMock;
  });

  Future<File> createFileWithBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  final pdfBytes = <int>[
    0x25,
    0x50,
    0x44,
    0x46,
    0x2D,
    0x31,
    0x2E,
    0x34,
    0x0A,
    0x25,
    0x25,
    0x45,
    0x4F,
    0x46,
  ];

  final pngBytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
  ];

  final jpgBytes = <int>[
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
    0x4A,
    0x46,
    0x49,
    0x46,
    0x00,
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
    test('does not delete anything when isMock = true (skips the loop)',
        () async {
      PdfCombiner.isMock = true;
      final mockTemp = MockDocumentUtils.getTemporalFolderPath();
      final fileInMockTemp = p.join(mockTemp, 'will_not_be_deleted.tmp');

      final file = await createFileWithBytes(fileInMockTemp, [1, 2, 3]);

      DocumentUtils.removeTemporalFiles([fileInMockTemp]);

      expect(File(fileInMockTemp).existsSync(), isTrue);

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

    test('deletes only files inside systemTemp when isMock = false', () async {
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

      final result = await DocumentUtils.isPDF(MergeInput.path(pdfPath));
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false for a file that is not PDF (e.g. PNG)', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_pdf2_');
      final pngPath = p.join(tempDir.path, 'image.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isPDF(MergeInput.path(pngPath));
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false when there is an exception (non-existent path)', () async {
      final nonExistent = p.join(Directory.systemTemp.path, 'no_such_file.pdf');
      expect(
        () => DocumentUtils.isPDF(MergeInput.path(nonExistent)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('isImage', () {
    test('true for PNG', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_png_');
      final pngPath = p.join(tempDir.path, 'img.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isImage(MergeInput.path(pngPath));
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('true for JPG/JPEG', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_jpg_');
      final jpgPath = p.join(tempDir.path, 'img.jpg');
      await createFileWithBytes(jpgPath, jpgBytes);

      final result = await DocumentUtils.isImage(MergeInput.path(jpgPath));
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false for PDF', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_pdf_');
      final pdfPath = p.join(tempDir.path, 'doc.pdf');
      await createFileWithBytes(pdfPath, pdfBytes);

      final result = await DocumentUtils.isImage(MergeInput.path(pdfPath));
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('throws when path does not exist', () async {
      final nonExistent =
          p.join(Directory.systemTemp.path, 'no_such_image.png');
      expect(
        () => DocumentUtils.isImage(MergeInput.path(nonExistent)),
        throwsA(isA<Exception>()),
      );
    });
  });
}
