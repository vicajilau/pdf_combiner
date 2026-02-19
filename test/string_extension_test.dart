import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/utils/string_extension.dart';

void main() {
  group('StringExtension', () {
    test('stringToMagicType detects PDF extension', () {
      expect('document.pdf'.stringToMagicType, FileMagicNumberType.pdf);
      expect('path/to/document.pdf'.stringToMagicType, FileMagicNumberType.pdf);
    });

    test('stringToMagicType detects PDF extension from URL', () {
      expect('https://example.com/document.pdf'.stringToMagicType,
          FileMagicNumberType.pdf);
      expect('https://example.com/document.pdf?query=1'.stringToMagicType,
          FileMagicNumberType.pdf);
    });

    test('stringToMagicType detects PNG extension', () {
      expect('image.png'.stringToMagicType, FileMagicNumberType.png);
    });

    test('stringToMagicType detects JPG extension', () {
      expect('image.jpg'.stringToMagicType, FileMagicNumberType.jpg);
      expect('image.jpeg'.stringToMagicType,
          FileMagicNumberType.unknown); 
    });

    test('stringToMagicType detects HEIC extension', () {
      expect('image.heic'.stringToMagicType, FileMagicNumberType.heic);
    });

    test('stringToMagicType handles unknown extension', () {
      expect('file.txt'.stringToMagicType, FileMagicNumberType.unknown);
      expect('file'.stringToMagicType, FileMagicNumberType.unknown);
    });

    test('stringToMagicType handles null', () {
      String? nullString;
      expect(nullString.stringToMagicType, FileMagicNumberType.unknown);
    });

    test('stringToMagicType handles empty string', () {
      expect(''.stringToMagicType, FileMagicNumberType.unknown);
    });

    test('stringToMagicType handles complex URLs', () {
      expect('https://example.com/doc.pdf#fragment'.stringToMagicType,
          FileMagicNumberType.pdf);
    });
  });
}