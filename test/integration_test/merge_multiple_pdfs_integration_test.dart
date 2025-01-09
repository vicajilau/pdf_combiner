import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('mergeMultiplePDFs Integration Tests', () {
    testWidgets('Test merging two PDFs', (tester) async {
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: ['test/samples/document_1.pdf', 'test/samples/document_2.pdf'],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, null);
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test merging with empty list', (tester) async {
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: [],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    testWidgets('Test merging with non-existing file', (tester) async {
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: ['test/samples/non_existing.pdf', 'test/samples/document_1.pdf'],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'File does not exist: test/samples/non_existing.pdf');
    });

    testWidgets('Test merging with non supported file', (tester) async {
      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: ['test/samples/document_1.pdf', 'test/samples/image_1.jpg'],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'Only PDF file allowed. File is not a pdf: test/samples/image_1.jpg');
    });

  });
}
