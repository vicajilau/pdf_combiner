
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';

void main() {
  group('PdfFromMultipleImageResponse', () {
    test('constructor assigns values correctly', () {
      final response = PdfFromMultipleImageResponse(
        status: PdfCombinerStatus.success,
        outputPath: 'path',
        message: 'Success',
      );

      expect(response.status, PdfCombinerStatus.success);
      expect(response.outputPath, 'path');
      expect(response.message, 'Success');
    });

    test('toString returns correct format', () {
      final response = PdfFromMultipleImageResponse(
        status: PdfCombinerStatus.success,
        outputPath: 'path',
        message: 'Success',
      );

      expect(
        response.toString(),
        'PdfFromMultipleImageResponse{outputPath: path, message: Success, status: PdfCombinerStatus.success }',
      );
    });
  });
}
