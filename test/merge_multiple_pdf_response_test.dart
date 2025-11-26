
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  group('MergeMultiplePDFResponse', () {
    test('constructor assigns values correctly', () {
      final response = MergeMultiplePDFResponse(
        status: PdfCombinerStatus.success,
        outputPath: 'path',
        message: 'Success',
      );

      expect(response.status, PdfCombinerStatus.success);
      expect(response.outputPath, 'path');
      expect(response.message, 'Success');
    });

    test('toString returns correct format', () {
      final response = MergeMultiplePDFResponse(
        status: PdfCombinerStatus.success,
        outputPath: 'path',
        message: 'Success',
      );

      expect(
        response.toString(),
        'MergeMultiplePDFResponse{outputPath: path, message: Success, status: PdfCombinerStatus.success }',
      );
    });
  });
}
