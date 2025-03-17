import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

import 'test_file_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestFileHelper.init();
  });

  group('createPDFFromMultipleImages Integration Tests', () {
    testWidgets('Test verificate if images input its inside of output path',
        (tester) async {
      final helper =
          TestFileHelper(['assets/image_1.jpeg', 'assets/image_2.png']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(await helper.verifyPDFUint8List([result.outputPath], inputPaths),
          true);
    });
    testWidgets('Test creating pdf from two images', (tester) async {
      final helper =
          TestFileHelper(['assets/image_1.jpeg', 'assets/image_2.png']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.outputPath, '${TestFileHelper.basePath}/merged_output.pdf');
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test creating pdf with empty list', (tester) async {
      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: [],
        outputPath: '${TestFileHelper.basePath}/assets/merged_output.pdf',
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message, 'The parameter (inputPaths) cannot be empty');
    });

    testWidgets('Test creating pdf with non-existing file', (tester) async {
      final helper = TestFileHelper([]);
      final inputPaths = await helper.prepareInputFiles();

      // Add a non-existing file path manually
      inputPaths.add('${TestFileHelper.basePath}/assets/non_existing.jpg');
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message,
          startsWith('File is not an image or does not exist:'));
    });

    testWidgets('Test creating pdf with non-supported file', (tester) async {
      final helper =
          TestFileHelper(['assets/document_1.pdf', 'assets/image_1.jpeg']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.outputPath, "");
      expect(result.message,
          'File is not an image or does not exist: ${TestFileHelper.basePath}/document_1.pdf');
    });
  });
}
