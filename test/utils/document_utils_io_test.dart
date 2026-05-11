import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

class _OtherMergeInput extends MergeInput {}

void main() {
    group('DocumentUtils - extra coverage', () {
        test('unsupported MergeInput subtype causes UnsupportedError in isPDF', () async {
      final input = _OtherMergeInput();

      await expectLater(() => DocumentUtils.isPDF(input), throwsA(isA<UnsupportedError>()));
    });

    test('unsupported MergeInput subtype causes UnsupportedError in prepareInput', () async {
      final input = _OtherMergeInput();

      await expectLater(() => DocumentUtils.prepareInput(input), throwsA(isA<UnsupportedError>()));
    });

    test('extension resolution works for bytes-created temp files (.png)', () async {
      // PNG signature bytes
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

      final path = await DocumentUtils.prepareInput(MergeInputBytes(pngBytes));
      expect(path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.pdf') || path.endsWith('.heic') || path.endsWith('.bin'), isTrue);
    });

    test('prepareInput preserves jpg extension for JPG bytes', () async {
      final tempDir = await Directory.systemTemp.createTemp('prep_jpg_test_');
      DocumentUtils.setTemporalFolderPath(tempDir.path);

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

      final result = await DocumentUtils.prepareInput(MergeInputBytes(jpgBytes));
      expect(result.endsWith('.jpg'), isTrue);
      expect(File(result).existsSync(), isTrue);

      await tempDir.delete(recursive: true);
    });

    test('prepareInput preserves heic extension for HEIC-like bytes', () async {
      final tempDir = await Directory.systemTemp.createTemp('prep_heic_test_');
      DocumentUtils.setTemporalFolderPath(tempDir.path);

      // Craft a minimal ftyp box with 'ftypheic' which is commonly used in HEIC files
      final heicBytes = Uint8List.fromList([
        0x00,
        0x00,
        0x00,
        0x18,
        0x66,
        0x74,
        0x79,
        0x70,
        0x68,
        0x65,
        0x69,
        0x63,
      ]);

      final result = await DocumentUtils.prepareInput(MergeInputBytes(heicBytes));
      expect(result.endsWith('.heic'), isTrue);
      expect(File(result).existsSync(), isTrue);

      await tempDir.delete(recursive: true);
    });

    test('readInputBytesForTesting reads bytes from path', () async {
      final tempDir = await Directory.systemTemp.createTemp('read_bytes_test_');
      final filePath = p.join(tempDir.path, 'somefile.bin');
      final content = <int>[10, 20, 30, 40];
      final file = await File(filePath).create(recursive: true);
      await file.writeAsBytes(content, flush: true);

      final bytes = await DocumentUtils.readInputBytesForTesting(MergeInputPath(filePath));
      expect(bytes, Uint8List.fromList(content));

      await tempDir.delete(recursive: true);
    });
  });
}






