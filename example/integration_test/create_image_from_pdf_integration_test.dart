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

  group('createImageFromPDF Integration Tests', () {
    testWidgets('Test creating images from PDF file', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('image_final.jpeg');

      final result = await PdfCombiner.createImageFromPDF(
        inputPath: inputPaths[0],
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response, ['${TestFileHelper.basePath}/image_final.jpeg']);
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test creating with non-existing file', (tester) async {
      final helper = TestFileHelper([]);
      final inputPaths = await helper.prepareInputFiles();
      inputPaths.add('${TestFileHelper.basePath}/assets/non_existing.pdf');
      final outputPath = await helper.getOutputFilePath("");

      final result = await PdfCombiner.createImageFromPDF(
        inputPath: inputPaths[0],
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message, 'File is not of PDF type or does not exist: ${inputPaths[0]}');
    });

    testWidgets('Test creating with non-supported file', (tester) async {
      final helper = TestFileHelper(['assets/image_1.jpeg']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createImageFromPDF(
        inputPath: inputPaths[0],
        outputPath: outputPath,
      );

      expect(result.status, PdfCombinerStatus.error);
      expect(result.response, null);
      expect(result.message,
          'File is not of PDF type or does not exist: ${inputPaths[0]}');
    });

    testWidgets('Test creating only one image from a PDF', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('image_final.jpeg');

      final result = await PdfCombiner.createImageFromPDF(
        inputPath: inputPaths[0],
        outputPath: outputPath,
        createOneImage: true
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response?.length, 1);
      expect(result.response, ['${TestFileHelper.basePath}/image_final.jpeg']);
      expect(result.message, 'Processed successfully');
    });

    testWidgets('Test creating four images from a PDF', (tester) async {
      final helper = TestFileHelper(['assets/document_3.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('image_final.jpeg');

      final result = await PdfCombiner.createImageFromPDF(
          inputPath: inputPaths[0],
          outputPath: outputPath,
          createOneImage: false
      );

      expect(result.status, PdfCombinerStatus.success);
      expect(result.response?.length, 4);
      expect(result.message, 'Processed successfully');
    });
  });
}
