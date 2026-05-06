import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:pdf_combiner/models/merge_input.dart';

class FakeMergeInput extends MergeInput {}

void main() {
  group('MergeInput model', () {
    test('getters, sourceLabel, requiresTemporaryResource and prefixes', () {
      final pathInput = MergeInputPath('/tmp/file.pdf');
      final bytesInput = MergeInputBytes(Uint8List.fromList([1, 2, 3]));
      final urlInput = MergeInputUrl('https://example.com/file.pdf');

      expect(pathInput.path, '/tmp/file.pdf');
      expect(pathInput.bytes, isNull);
      expect(pathInput.url, isNull);
      expect(pathInput.sourceLabel, '/tmp/file.pdf');
      expect(pathInput.requiresTemporaryResource, isFalse);
      expect(pathInput.temporaryFilePrefix, 'path_input');
      expect(pathInput.toString(), '/tmp/file.pdf');

      expect(bytesInput.path, isNull);
      expect(bytesInput.bytes, isNotNull);
      expect(bytesInput.url, isNull);
      expect(bytesInput.sourceLabel, 'File in bytes');
      expect(bytesInput.requiresTemporaryResource, isTrue);
      expect(bytesInput.temporaryFilePrefix, 'bytes_input');
      expect(bytesInput.toString(), bytesInput.bytes.toString());

      expect(urlInput.path, isNull);
      expect(urlInput.bytes, isNull);
      expect(urlInput.url, 'https://example.com/file.pdf');
      expect(urlInput.sourceLabel, 'https://example.com/file.pdf');
      expect(urlInput.requiresTemporaryResource, isTrue);
      expect(urlInput.temporaryFilePrefix, 'url_input');
      expect(urlInput.toString(), 'https://example.com/file.pdf');
    });

    test('temporaryFilePrefix throws for unknown subtype', () {
      final fake = FakeMergeInput();
      expect(() => fake.temporaryFilePrefix, throwsStateError);
    });
  });
}

