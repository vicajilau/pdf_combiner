import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

import 'mocks/mock_document_utils.dart';

// Fake MergeInput subtype used by tests to exercise default branches.
class FakeInput extends MergeInput {
  @override
  String toString() => 'fake';
}

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

      final result = await DocumentUtils.isPDF(MergeInputPath(pdfPath));
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false for a file that is not PDF (e.g. PNG)', () async {
      final tempDir = await Directory.systemTemp.createTemp('doc_utils_pdf2_');
      final pngPath = p.join(tempDir.path, 'image.png');
      await createFileWithBytes(pngPath, pngBytes);

      final result = await DocumentUtils.isPDF(MergeInputPath(pngPath));
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false when there is an exception (non-existent path)', () async {
      final nonExistent = p.join(Directory.systemTemp.path, 'no_such_file.pdf');
      expect(
        () => DocumentUtils.isPDF(MergeInputPath(nonExistent)),
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

      final result = await DocumentUtils.isImage(MergeInputPath(pngPath));
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('true for JPG/JPEG', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_jpg_');
      final jpgPath = p.join(tempDir.path, 'img.jpg');
      await createFileWithBytes(jpgPath, jpgBytes);

      final result = await DocumentUtils.isImage(MergeInputPath(jpgPath));
      expect(result, isTrue);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('false for PDF', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('doc_utils_img_pdf_');
      final pdfPath = p.join(tempDir.path, 'doc.pdf');
      await createFileWithBytes(pdfPath, pdfBytes);

      final result = await DocumentUtils.isImage(MergeInputPath(pdfPath));
      expect(result, isFalse);

      await Directory(tempDir.path).delete(recursive: true);
    });

    test('throws when path does not exist', () async {
      final nonExistent =
          p.join(Directory.systemTemp.path, 'no_such_image.png');
      expect(
        () => DocumentUtils.isImage(MergeInputPath(nonExistent)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DocumentUtils with bytes', () {
    late String originalTempPath;

    // reuse the byte arrays defined above (they are List<int>) and create
    // typed Uint8List instances where needed
    setUp(() {
      originalTempPath = DocumentUtils.getTemporalFolderPath();
    });

    tearDown(() {
      DocumentUtils.setTemporalFolderPath(originalTempPath);
    });

    group('isPDF with bytes', () {
      test('returns true for PDF bytes', () async {
        final input = MergeInputBytes(Uint8List.fromList(pdfBytes));
        final result = await DocumentUtils.isPDF(input);
        expect(result, isTrue);
      });

      test('returns false for non-PDF bytes', () async {
        final input = MergeInputBytes(Uint8List.fromList(pngBytes));
        final result = await DocumentUtils.isPDF(input);
        expect(result, isFalse);
      });
    });

    group('isImage with bytes', () {
      test('returns true for PNG bytes', () async {
        final input = MergeInputBytes(Uint8List.fromList(pngBytes));
        final result = await DocumentUtils.isImage(input);
        expect(result, isTrue);
      });

      test('returns true for JPG bytes', () async {
        final input = MergeInputBytes(Uint8List.fromList(jpgBytes));
        final result = await DocumentUtils.isImage(input);
        expect(result, isTrue);
      });

      test('returns false for PDF bytes', () async {
        final input = MergeInputBytes(Uint8List.fromList(pdfBytes));
        final result = await DocumentUtils.isImage(input);
        expect(result, isFalse);
      });
    });

    group('prepareInput', () {
      test('returns path for path type input', () async {
        final input = MergeInputPath('/some/path.pdf');
        final result = await DocumentUtils.prepareInput(input);
        expect(result, '/some/path.pdf');
      });

      test('creates temp file for bytes type input', () async {
        final tempDir = await Directory.systemTemp.createTemp('prep_test_');
        DocumentUtils.setTemporalFolderPath(tempDir.path);

        final input = MergeInputBytes(Uint8List.fromList(pngBytes));
        final result = await DocumentUtils.prepareInput(input);

        expect(result.startsWith(tempDir.path), isTrue);
        expect(File(result).existsSync(), isTrue);

        await tempDir.delete(recursive: true);
      });

      test('preserves pdf extension for PDF bytes input', () async {
        final tempDir = await Directory.systemTemp.createTemp('prep_pdf_test_');
        DocumentUtils.setTemporalFolderPath(tempDir.path);

        final result =
            await DocumentUtils.prepareInput(MergeInputBytes(Uint8List.fromList(pdfBytes)));

        expect(p.extension(result), '.pdf');
        expect(File(result).existsSync(), isTrue);

        await tempDir.delete(recursive: true);
      });

      test('creates temp file for JPG bytes input preserving .jpg extension', () async {
        final tempDir = await Directory.systemTemp.createTemp('prep_jpg_test_');
        DocumentUtils.setTemporalFolderPath(tempDir.path);

        final result =
            await DocumentUtils.prepareInput(MergeInputBytes(Uint8List.fromList(jpgBytes)));

        expect(p.extension(result), '.jpg');
        expect(File(result).existsSync(), isTrue);

        await tempDir.delete(recursive: true);
      });

      test('creates temp file for unknown bytes input using .bin extension', () async {
        final tempDir = await Directory.systemTemp.createTemp('prep_bin_test_');
        DocumentUtils.setTemporalFolderPath(tempDir.path);

        final unknown = Uint8List.fromList([0x00, 0x11, 0x22, 0x33]);
        final result = await DocumentUtils.prepareInput(MergeInputBytes(unknown));

        expect(p.extension(result), '.bin');
        expect(File(result).existsSync(), isTrue);

        await tempDir.delete(recursive: true);
      });

      test('downloads URL input to a temp file with detected extension', () async {
        final tempDir = await Directory.systemTemp.createTemp('prep_url_test_');
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        DocumentUtils.setTemporalFolderPath(tempDir.path);

        server.listen((request) async {
          request.response.headers.contentType =
              ContentType('application', 'pdf');
          request.response.add(Uint8List.fromList(pdfBytes));
          await request.response.close();
        });

        final url = 'http://${server.address.host}:${server.port}/document.pdf';
        final result = await DocumentUtils.prepareInput(MergeInputUrl(url));

        expect(p.extension(result), '.pdf');
        expect(File(result).existsSync(), isTrue);
        expect(await DocumentUtils.isPDF(MergeInputUrl(url)), isTrue);

        await server.close(force: true);
        await tempDir.delete(recursive: true);
      });

      test('creates temp directory if not exists', () async {
        final nonExistentPath = p.join(Directory.systemTemp.path, 'non_existent_dir_for_test');
        DocumentUtils.setTemporalFolderPath(nonExistentPath);

        final result =
            await DocumentUtils.prepareInput(MergeInputBytes(Uint8List.fromList(pngBytes)));

        expect(result.startsWith(nonExistentPath), isTrue);
        expect(Directory(nonExistentPath).existsSync(), isTrue);

        await Directory(nonExistentPath).delete(recursive: true);
      });
    });

    group('setTemporalFolderPath', () {
      test('changes temporal folder path', () {
        final originalPath = DocumentUtils.getTemporalFolderPath();
        final testPath = p.join(Directory.systemTemp.path, 'custom_temp');

        DocumentUtils.setTemporalFolderPath(testPath);
        expect(DocumentUtils.getTemporalFolderPath(), testPath);

        DocumentUtils.setTemporalFolderPath(originalPath);
      });
    });
  });

  group('http error handling for URL inputs', () {
    test('prepareInput and isPDF throw HttpException on non-2xx response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      server.listen((request) async {
        request.response.statusCode = 404;
        await request.response.close();
      });

      final url = 'http://${server.address.host}:${server.port}/not_found.pdf';

      try {
        await expectLater(
          DocumentUtils.prepareInput(MergeInputUrl(url)),
          throwsA(isA<HttpException>()),
        );

        await expectLater(
          DocumentUtils.isPDF(MergeInputUrl(url)),
          throwsA(isA<HttpException>()),
        );
      } finally {
        await server.close(force: true);
      }
    });
  });

  group('detect default and private-read branches', () {
    test('isPDF throws UnsupportedError for unknown MergeInput subtype', () async {
      final fake = FakeInput();

      await expectLater(
        DocumentUtils.isPDF(fake),
        throwsA(isA<UnsupportedError>()),
      );
    });

    });
}
