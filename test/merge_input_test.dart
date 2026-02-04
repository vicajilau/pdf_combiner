import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/merge_input.dart';

void main() {
  group('MergeInput', () {
    test('path constructor creates MergeInput with path type', () {
      final input = MergeInput.path('/path/to/file.pdf');

      expect(input.type, MergeInputType.path);
      expect(input.path, '/path/to/file.pdf');
      expect(input.bytes, isNull);
      expect(input.url, isNull);
      expect(input.type == MergeInputType.bytes, isFalse);
      expect(input.type == MergeInputType.url, isFalse);
      expect(input.type == MergeInputType.path, isTrue);
    });

    test('bytes constructor creates MergeInput with bytes type', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final input = MergeInput.bytes(bytes);

      expect(input.type, MergeInputType.bytes);
      expect(input.bytes, bytes);
      expect(input.path, isNull);
      expect(input.url, isNull);
      expect(input.type == MergeInputType.bytes, isTrue);
      expect(input.type == MergeInputType.path, isFalse);
      expect(input.type == MergeInputType.url, isFalse);
    });

    test('url constructor creates MergeInput with url type', () {
      final input = MergeInput.url('Https://example.com/file.pdf');

      expect(input.type, MergeInputType.url);
      expect(input.path, isNull);
      expect(input.bytes, isNull);
      expect(input.url, 'Https://example.com/file.pdf');
      expect(input.type == MergeInputType.bytes, isFalse);
      expect(input.type == MergeInputType.path, isFalse);
      expect(input.type == MergeInputType.url, isTrue);
    });


    test('toString returns path for path type', () {
      final input = MergeInput.path('/path/to/file.pdf');

      expect(input.toString(), '/path/to/file.pdf');
    });

    test('toString returns bytes string for bytes type', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final input = MergeInput.bytes(bytes);

      expect(input.toString(), bytes.toString());
    });

    test('toString returns url for url type', () {
      final input = MergeInput.url('Https://example.com/file.pdf');

      expect(input.toString(), 'Https://example.com/file.pdf');
    });
  });
}
