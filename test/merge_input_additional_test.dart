import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/merge_input.dart';

class _OtherMergeInput extends MergeInput {}

void main() {
  group('MergeInput - additional', () {
    test('temporaryFilePrefix for path and bytes', () {
      final p = MergeInputPath('/tmp/file.pdf');
      final b = MergeInputBytes(Uint8List.fromList([1, 2, 3]));

      expect(p.temporaryFilePrefix, 'path_input');
      expect(b.temporaryFilePrefix, 'bytes_input');
    });

    test('unsupported subtype temporaryFilePrefix throws StateError', () {
      final other = _OtherMergeInput();
      expect(() => other.temporaryFilePrefix, throwsA(isA<StateError>()));
    });
  });
}

