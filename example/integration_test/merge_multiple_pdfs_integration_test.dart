import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'test_file_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('mergeMultiplePDFs Integration Tests', () {
    testWidgets('Test merging two PDFs', (tester) async {
      final helper =
          TestFileHelper(['assets/document_1.pdf', 'assets/document_2.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, '${TestFileHelper.basePath}merged_output.pdf');
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test merging single PDF file', (tester) async {
      final helper =
      TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, '${TestFileHelper.basePath}merged_output.pdf');
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test merging with empty list', (tester) async {
      final helper = TestFileHelper([]);
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: [],
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    testWidgets('Test merging with non-existing file', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();

      inputPaths.add('${TestFileHelper.basePath}non_existing.pdf');

      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, startsWith('File does not exist'));
    });

    testWidgets('Test merging with non-supported file', (tester) async {
      final helper =
          TestFileHelper(['assets/document_1.pdf', 'assets/image_1.jpg']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, startsWith('Only PDF file allowed'));
    });
  });
}
