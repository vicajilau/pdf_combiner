import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils_io.dart';

void main() {
  group('DocumentUtils IO', () {
    late Directory tempDir;
    final originalTemp = DocumentUtils.getTemporalFolderPath();
    final originalMock = PdfCombiner.isMock;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_combiner_test_');
      DocumentUtils.setTemporalFolderPath(tempDir.path);
      PdfCombiner.isMock = false;
    });

    tearDown(() async {
      PdfCombiner.isMock = originalMock;
      DocumentUtils.setTemporalFolderPath(originalTemp);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('prepareInput writes bytes to a .pdf file when bytes look like a PDF', () async {
      // PDF files start with '%PDF'
      final pdfMagic = <int>[0x25, 0x50, 0x44, 0x46, 0x2D];
      final bytes = Uint8List.fromList([...pdfMagic, 0, 1, 2, 3]);

      final path = await DocumentUtils.prepareInput(MergeInputBytes(bytes));

      expect(path.startsWith(tempDir.path), isTrue);
      expect(path.endsWith('.pdf'), isTrue);
      expect(File(path).existsSync(), isTrue);

      // cleanup created file
      DocumentUtils.removeTemporalFiles([path]);
      expect(File(path).existsSync(), isFalse);
    });

    test('removeTemporalFiles respects PdfCombiner.isMock flag', () async {
      final file = File('${tempDir.path}/to_delete.txt');
      await file.writeAsBytes([1, 2, 3]);

      PdfCombiner.isMock = true;
      DocumentUtils.removeTemporalFiles([file.path]);
      expect(file.existsSync(), isTrue);

      PdfCombiner.isMock = false;
      DocumentUtils.removeTemporalFiles([file.path]);
      expect(file.existsSync(), isFalse);
    });
  });
}

