
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/responses/generate_pdf_from_documents_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  group('GeneratePdfFromDocumentsResponse', () {
    test('constructor assigns values correctly', () {
      final response = GeneratePdfFromDocumentsResponse(
        status: PdfCombinerStatus.success,
        outputPath: 'path',
        message: 'Success',
      );

      expect(response.status, PdfCombinerStatus.success);
      expect(response.outputPath, 'path');
      expect(response.message, 'Success');
    });

    test('toString returns correct format', () {
      final response = GeneratePdfFromDocumentsResponse(
        status: PdfCombinerStatus.success,
        outputPath: 'path',
        message: 'Success',
      );

      expect(
        response.toString(),
        'GeneratePdfFromDocumentsResponse{outputPath: path, message: Success, status: PdfCombinerStatus.success }',
      );
    });
  });
}
