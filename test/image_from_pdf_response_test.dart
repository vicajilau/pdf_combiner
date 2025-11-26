
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  group('ImageFromPDFResponse', () {
    test('constructor assigns values correctly', () {
      final response = ImageFromPDFResponse(
        status: PdfCombinerStatus.success,
        outputPaths: ['path1', 'path2'],
        message: 'Success',
      );

      expect(response.status, PdfCombinerStatus.success);
      expect(response.outputPaths, ['path1', 'path2']);
      expect(response.message, 'Success');
    });

    test('toString returns correct format', () {
      final response = ImageFromPDFResponse(
        status: PdfCombinerStatus.success,
        outputPaths: ['path1', 'path2'],
        message: 'Success',
      );

      expect(
        response.toString(),
        'ImageFromPDFResponse{outputPaths: [path1, path2], message: Success, status: PdfCombinerStatus.success }',
      );
    });
  });
}
