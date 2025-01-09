import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('createPDFFromMultipleImages Integration Tests', () {
    testWidgets('Test creating pdf from two images', (tester) async {
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: ['test/samples/image.jpg', 'test/samples/image_2.png'],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, null);
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test creating pdf with empty list', (tester) async {
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    testWidgets('Test creating pdf with non-existing file', (tester) async {
      const failedFile= "test/samples/non_existing.jpg";
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [
          failedFile,
          'test/samples/image_2.png'
        ],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(
          result.message, 'File does not exist: $failedFile');
    });

    testWidgets('Test creating pdf with non supported file', (tester) async {
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: ['test/samples/dummy.pdf', 'test/samples/image.jpg'],
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message,
          'Only Image file allowed. File is not an image: test/samples/dummy.pdf');
    });
  });
}
