import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('createImageFromPDF Integration Tests', () {

    testWidgets('Test creating images from PDF file', (tester) async {
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'assets/document_1.pdf',
        outputPath: 'assets/image_final.jpeg',
      );

      debugPrint("result: $result");

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, null);
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test creating with non-existing file', (tester) async {
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: 'test/samples/non_existing.pdf',
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'File does not exist: test/samples/non_existing.pdf');
    });

    testWidgets('Test creating with non supported file', (tester) async {
      const inputPath = 'test/samples/image_1.jpg';
      final result = await PdfCombiner.createImageFromPDF(
        inputPath: inputPath,
        outputPath: 'test/samples/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'Only Image file allowed. File is not an image: $inputPath');
    });

  });
}
