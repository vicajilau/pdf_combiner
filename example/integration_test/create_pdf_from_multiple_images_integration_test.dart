import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'test_file_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const basePath =
      "/data/user/0/com.victorcarreras.pdf_combiner_example/app_flutter/";

  group('createPDFFromMultipleImages Integration Tests', () {
    testWidgets('Test creating pdf from two images', (tester) async {
      final helper =
          TestFileHelper(['assets/image_1.jpg', 'assets/image_2.png']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, '${basePath}merged_output.pdf');
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test creating pdf with empty list', (tester) async {
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [],
        outputPath: '${basePath}assets/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    testWidgets('Test creating pdf with non-existing file', (tester) async {
      final helper = TestFileHelper([]);
      final inputPaths = await helper.prepareInputFiles();

      // Add a non-existing file path manually
      inputPaths.add('${basePath}assets/non_existing.jpg');
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, startsWith('File does not exist'));
    });

    testWidgets('Test creating pdf with non-supported file', (tester) async {
      final helper = TestFileHelper([
        'assets/document_1.pdf',
        'assets/image_1.jpg'
      ]);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message,
          'Only Image file allowed. File is not an image: ${basePath}document_1.pdf');
    });
  });
}
