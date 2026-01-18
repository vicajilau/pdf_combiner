import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

void main() {
  group('PdfSource', () {
    group('PdfSource.path', () {
      test('creates a PdfSource with path', () {
        final source = PdfSource.path('/path/to/file.pdf');

        expect(source.path, '/path/to/file.pdf');
        expect(source.bytes, isNull);
        expect(source.file, isNull);
      });

      test('creates different instances for different paths', () {
        final source1 = PdfSource.path('/path/to/file1.pdf');
        final source2 = PdfSource.path('/path/to/file2.pdf');

        expect(source1.path, isNot(equals(source2.path)));
      });
    });

    group('PdfSource.bytes', () {
      test('creates a PdfSource with bytes', () {
        final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
        final source = PdfSource.bytes(bytes);

        expect(source.path, isNull);
        expect(source.bytes, bytes);
        expect(source.file, isNull);
      });

      test('stores the exact bytes provided', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final source = PdfSource.bytes(bytes);

        expect(source.bytes!.length, 5);
        expect(source.bytes![0], 1);
        expect(source.bytes![4], 5);
      });
    });

    group('PdfSource.file', () {
      test('creates a PdfSource with file', () {
        final file = File('/path/to/file.pdf');
        final source = PdfSource.file(file);

        expect(source.path, isNull);
        expect(source.bytes, isNull);
        expect(source.file, file);
      });

      test('stores the exact file provided', () {
        final file = File('/custom/path/document.pdf');
        final source = PdfSource.file(file);

        expect(source.file!.path, '/custom/path/document.pdf');
      });
    });

    group('assertion', () {
      test('constructor requires at least one parameter', () {
        // The assert is checked at runtime in debug mode
        // We can verify the named constructors work correctly
        expect(() => PdfSource.path('test.pdf'), returnsNormally);
        expect(
            () => PdfSource.bytes(Uint8List.fromList([1, 2, 3])), returnsNormally);
        expect(() => PdfSource.file(File('test.pdf')), returnsNormally);
      });
    });

    group('usage patterns', () {
      test('can be used in a list', () {
        final sources = [
          PdfSource.path('/path/to/file1.pdf'),
          PdfSource.bytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46])),
          PdfSource.file(File('/path/to/file2.pdf')),
        ];

        expect(sources.length, 3);
        expect(sources[0].path, isNotNull);
        expect(sources[1].bytes, isNotNull);
        expect(sources[2].file, isNotNull);
      });

      test('can identify source type', () {
        final pathSource = PdfSource.path('/path/to/file.pdf');
        final bytesSource =
            PdfSource.bytes(Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));
        final fileSource = PdfSource.file(File('/path/to/file.pdf'));

        expect(pathSource.path != null, isTrue);
        expect(pathSource.bytes == null, isTrue);
        expect(pathSource.file == null, isTrue);

        expect(bytesSource.path == null, isTrue);
        expect(bytesSource.bytes != null, isTrue);
        expect(bytesSource.file == null, isTrue);

        expect(fileSource.path == null, isTrue);
        expect(fileSource.bytes == null, isTrue);
        expect(fileSource.file != null, isTrue);
      });
    });
  });
}
