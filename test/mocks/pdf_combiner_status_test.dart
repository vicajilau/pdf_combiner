import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  group('PdfCombinerStatus.from', () {
    test('should return PdfCombinerStatus.empty for "empty"', () {
      expect(PdfCombinerStatus.from("empty"), PdfCombinerStatus.empty);
    });

    test('should return PdfCombinerStatus.success for "success"', () {
      expect(PdfCombinerStatus.from("success"), PdfCombinerStatus.success);
    });

    test('should return PdfCombinerStatus.error for "error"', () {
      expect(PdfCombinerStatus.from("error"), PdfCombinerStatus.error);
    });

    test('should return PdfCombinerStatus.processing for "processing"', () {
      expect(
          PdfCombinerStatus.from("processing"), PdfCombinerStatus.processing);
    });

    test('should return PdfCombinerStatus.unknown for unrecognized string', () {
      expect(
          PdfCombinerStatus.from("invalid_status"), PdfCombinerStatus.unknown);
      expect(PdfCombinerStatus.from(""), PdfCombinerStatus.unknown);
    });
  });
}
