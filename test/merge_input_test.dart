import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/models/merge_input.dart';

void main() {
  group('MergeInput Tests', () {
    test('MergeInputPath stores path correctly', () {
      const path = '/path/to/file.pdf';
      final input = MergeInputPath(path);
      expect(input.path, path);
    });

    test('MergeInputBytes stores bytes correctly', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final input = MergeInputBytes(bytes);
      expect(input.bytes, bytes);
    });

    // Note: DocumentUtils.prepareInput logic for IO involves file creation,
    // which relies on getTemporaryDirectory (via path_provider) and file access.
    // DocumentUtils implementation in the plugin uses conditional imports.
    // Testing the exact file creation in unit tests might require robust mocking of path_provider
    // or integration tests. Here we verify the model behavior primarily.
  });
}
