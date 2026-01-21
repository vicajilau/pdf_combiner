import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/models/merge_input_type.dart';

void main() {
  group('MergeInput', () {
    test('path constructor creates MergeInput with path type', () {
      final input = MergeInput.path('/path/to/file.pdf');

      expect(input.type, MergeInputType.path);
      expect(input.path, '/path/to/file.pdf');
      expect(input.bytes, isNull);
      expect(input.type.isTemporal, isFalse);
    });

    test('bytes constructor creates MergeInput with bytes type', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
      final input = MergeInput.bytes(bytes);

      expect(input.type, MergeInputType.bytes);
      expect(input.bytes, bytes);
      expect(input.path, isNull);
      expect(input.type.isTemporal, isTrue);
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
  });
}
