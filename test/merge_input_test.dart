import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/merge_input.dart';

void main() {
  group('MergeInput', () {
    test('MergeInputPath expone el path y no bytes', () {
      final input = MergeInputPath('/path/to/file.pdf');

      expect(input, isA<MergeInputPath>());
      expect(input.path, '/path/to/file.pdf');
      expect(input.bytes, isNull);
      expect(input.url, isNull);
      expect(input.requiresTemporaryResource, isFalse);
    });

    test('MergeInputBytes expone los bytes y requiere recurso temporal', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final input = MergeInputBytes(bytes);

      expect(input, isA<MergeInputBytes>());
      expect(input.bytes, bytes);
      expect(input.path, isNull);
      expect(input.url, isNull);
      expect(input.requiresTemporaryResource, isTrue);
    });

    test('MergeInputUrl expone la url y requiere recurso temporal', () {
      final input = MergeInputUrl('https://example.com/file.pdf');

      expect(input, isA<MergeInputUrl>());
      expect(input.url, 'https://example.com/file.pdf');
      expect(input.path, isNull);
      expect(input.bytes, isNull);
      expect(input.sourceLabel, 'https://example.com/file.pdf');
      expect(input.requiresTemporaryResource, isTrue);
    });

    test('toString returns path for path type', () {
      final input = MergeInputPath('/path/to/file.pdf');

      expect(input.toString(), '/path/to/file.pdf');
    });

    test('toString returns bytes string for bytes type', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final input = MergeInputBytes(bytes);

      expect(input.toString(), bytes.toString());
    });

    test('sourceLabel returns friendly label for bytes type', () {
      final input = MergeInputBytes(Uint8List.fromList([1, 2, 3]));

      expect(input.sourceLabel, 'File in bytes');
    });
  });
}
