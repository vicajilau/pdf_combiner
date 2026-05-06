import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

void main() {
  group('DocumentUtils with bytes', () {
    late String originalTempPath;

    final pdfBytes = Uint8List.fromList([
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
    ]);

    final pngBytes = Uint8List.fromList([
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
    ]);

    final jpgBytes = Uint8List.fromList([
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
    ]);

    setUp(() {
      originalTempPath = DocumentUtils.getTemporalFolderPath();
    });

    tearDown(() {
      DocumentUtils.setTemporalFolderPath(originalTempPath);
    });

    group('isPDF with bytes', () {
      test('returns true for PDF bytes', () async {
        final input = MergeInputBytes(pdfBytes);
        final result = await DocumentUtils.isPDF(input);
        expect(result, isTrue);
      });

      test('returns false for non-PDF bytes', () async {
        final input = MergeInputBytes(pngBytes);
        final result = await DocumentUtils.isPDF(input);
        expect(result, isFalse);
      });
    });

    group('isImage with bytes', () {
      test('returns true for PNG bytes', () async {
        final input = MergeInputBytes(pngBytes);
        final result = await DocumentUtils.isImage(input);
        expect(result, isTrue);
      });

      test('returns true for JPG bytes', () async {
        final input = MergeInputBytes(jpgBytes);
        final result = await DocumentUtils.isImage(input);
        expect(result, isTrue);
      });

      test('returns false for PDF bytes', () async {
        final input = MergeInputBytes(pdfBytes);
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

        final input = MergeInputBytes(pngBytes);
        final result = await DocumentUtils.prepareInput(input);

        expect(result.startsWith(tempDir.path), isTrue);
        expect(File(result).existsSync(), isTrue);

        await tempDir.delete(recursive: true);
      });

      test('preserves pdf extension for PDF bytes input', () async {
        final tempDir = await Directory.systemTemp.createTemp('prep_pdf_test_');
        DocumentUtils.setTemporalFolderPath(tempDir.path);

        final result =
            await DocumentUtils.prepareInput(MergeInputBytes(pdfBytes));

        expect(p.extension(result), '.pdf');
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
          request.response.add(pdfBytes);
          await request.response.close();
        });

        final url =
            'http://${server.address.host}:${server.port}/document.pdf';
        final result = await DocumentUtils.prepareInput(MergeInputUrl(url));

        expect(p.extension(result), '.pdf');
        expect(File(result).existsSync(), isTrue);
        expect(await DocumentUtils.isPDF(MergeInputUrl(url)), isTrue);

        await server.close(force: true);
        await tempDir.delete(recursive: true);
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
}
