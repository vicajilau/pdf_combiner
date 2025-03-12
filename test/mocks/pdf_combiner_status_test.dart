import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  group('PdfCombinerStatus.from', () {
    test('should return PdfCombinerStatus.success for "success"', () {
      expect(PdfCombinerStatus.from("success"), PdfCombinerStatus.success);
    });

    test('should return PdfCombinerStatus.error for "error"', () {
      expect(PdfCombinerStatus.from("error"), PdfCombinerStatus.error);
    });
  });
}
