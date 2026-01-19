import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

void main() {
  group('MergeInput', () {
    group('MergeInput.path', () {
      test('creates a MergeInput with path', () {
        final source = MergeInput.path('/path/to/file.pdf');

        expect(source.path, '/path/to/file.pdf');
        expect(source.bytes, isNull);
      });

      test('creates different instances for different paths', () {
        final source1 = MergeInput.path('/path/to/file1.pdf');
        final source2 = MergeInput.path('/path/to/file2.pdf');

        expect(source1.path, isNot(equals(source2.path)));
      });
    });

    group('MergeInput.bytes', () {
      test('creates a MergeInput with bytes', () {
        final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
        final source = MergeInput.bytes(bytes);

        expect(source.path, isNull);
        expect(source.bytes, bytes);
      });

      test('stores the exact bytes provided', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final source = MergeInput.bytes(bytes);

        expect(source.bytes!.length, 5);
        expect(source.bytes![0], 1);
        expect(source.bytes![4], 5);
      });
    });
  });
}
