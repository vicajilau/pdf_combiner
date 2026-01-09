import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import 'test_file_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestFileHelper.init();
  });

  group('createPDFFromMultipleImages Integration Tests', () {
    testWidgets('Test creating pdf from two images', (tester) async {
      final helper =
          TestFileHelper(['assets/image_1.jpeg', 'assets/image_2.png']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      expect(result, '${TestFileHelper.basePath}/merged_output.pdf');
    }, timeout: Timeout.none);

    testWidgets('Test creating pdf with empty list', (tester) async {
      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: [],
          outputPath: '${TestFileHelper.basePath}/assets/merged_output.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The parameter (inputPaths) cannot be empty',
          ),
        ),
      );
    }, timeout: Timeout.none);

    testWidgets('Test creating pdf with non-existing file', (tester) async {
      final helper = TestFileHelper([]);
      final inputPaths = await helper.prepareInputFiles();
      inputPaths.add('${TestFileHelper.basePath}/assets/non_existing.jpg');
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: inputPaths,
          outputPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message.startsWith(
                  'File is not an image or does not exist:',
                ),
          ),
        ),
      );
    }, timeout: Timeout.none);

    testWidgets('Test creating pdf with non-supported file', (tester) async {
      final helper =
          TestFileHelper(['assets/document_1.pdf', 'assets/image_1.jpeg']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputPaths: inputPaths,
          outputPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message ==
                    'File is not an image or does not exist: ${TestFileHelper.basePath}/document_1.pdf',
          ),
        ),
      );
    }, timeout: Timeout.none);
  });
}
