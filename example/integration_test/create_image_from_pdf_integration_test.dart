import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

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
      final outputPath = await helper.getOutputFilePath();

      final result = await PdfCombiner.createImageFromPDF(
        inputPath: inputPaths[0],
        outputDirPath: outputPath,
      );

      expect(result, ['${TestFileHelper.basePath}/image_1.png']);
    }, timeout: Timeout.none);

    testWidgets('Test creating with non-existing file', (tester) async {
      final helper = TestFileHelper([]);
      final inputPaths = await helper.prepareInputFiles();
      inputPaths.add('${TestFileHelper.basePath}/assets/non_existing.pdf');
      final outputPath = await helper.getOutputFilePath("");

      expect(
        () => PdfCombiner.createImageFromPDF(
          inputPath: inputPaths[0],
          outputDirPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'File is not of PDF type or does not exist: ${inputPaths[0]}',
          ),
        ),
      );
    }, timeout: Timeout.none);

    testWidgets('Test creating with non-supported file', (tester) async {
      final helper = TestFileHelper(['assets/image_1.jpeg']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      expect(
        () => PdfCombiner.createImageFromPDF(
          inputPath: inputPaths[0],
          outputDirPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'File is not of PDF type or does not exist: ${inputPaths[0]}',
          ),
        ),
      );
    }, timeout: Timeout.none);

    testWidgets('Test creating only one image from a PDF', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath();

      final result = await PdfCombiner.createImageFromPDF(
          inputPath: inputPaths[0], outputDirPath: outputPath);

      expect(result.length, 1);
      expect(result, ['${TestFileHelper.basePath}/image_1.png']);
    }, timeout: Timeout.none);

    testWidgets('Test creating four images from a PDF', (tester) async {
      final helper = TestFileHelper(['assets/document_3.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath();

      final result = await PdfCombiner.createImageFromPDF(
          inputPath: inputPaths[0],
          outputDirPath: outputPath,
          config: ImageFromPdfConfig(createOneImage: false));

      expect(result.length, 4);
      await helper.deleteFiles();
    }, timeout: Timeout.none);
  });
}
