import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import 'test_file_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await TestFileHelper.init();
  });

  group('createImageFromPDF Integration Tests', () {
    testWidgets('Test creating images from PDF file', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath();

      final result = await PdfCombiner.createImageFromPDF(
        input: MergeInput.path(inputPaths[0]),
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
          input: MergeInput.path(inputPaths[0]),
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
          input: MergeInput.path(inputPaths[0]),
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
          input: MergeInput.path(inputPaths[0]), outputDirPath: outputPath);

      expect(result.length, 1);
      expect(result, ['${TestFileHelper.basePath}/image_1.png']);
    }, timeout: Timeout.none);

    testWidgets('Test creating four images from a PDF', (tester) async {
      final helper = TestFileHelper(['assets/document_3.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath();

      final result = await PdfCombiner.createImageFromPDF(
          input: MergeInput.path(inputPaths[0]),
          outputDirPath: outputPath,
          config: ImageFromPdfConfig(createOneImage: false));

      expect(result.length, 4);
    }, timeout: Timeout.none);
  });
  group('createPDFFromMultipleImages Integration Tests', () {
    testWidgets('Test creating pdf from two images', (tester) async {
      final helper =
          TestFileHelper(['assets/image_1.jpeg', 'assets/image_2.png']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.createPDFFromMultipleImages(
        inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
        outputPath: outputPath,
      );

      expect(result, '${TestFileHelper.basePath}/merged_output.pdf');
    }, timeout: Timeout.none);

    testWidgets('Test creating pdf with empty list', (tester) async {
      expect(
        () => PdfCombiner.createPDFFromMultipleImages(
          inputs: [],
          outputPath: '${TestFileHelper.basePath}/assets/merged_output.pdf',
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The parameter (inputs) cannot be empty',
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
          inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
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
          inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
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
  testWidgets('createPdfFromMultipleImages parses HEIC',
      (WidgetTester tester) async {
    final helper = TestFileHelper(['assets/sample.heic']);
    final filePaths = await helper.prepareInputFiles();
    final sampleHeicPath = filePaths.first;

    final outputPath = await helper.getOutputFilePath('output_heic.pdf');

    final outputFile = File(outputPath);
    if (outputFile.existsSync()) {
      outputFile.deleteSync();
    }

    await tester.runAsync(() async {
      await PdfCombiner.createPDFFromMultipleImages(
        inputs: [MergeInput.path(sampleHeicPath)],
        outputPath: outputPath,
      );
    });

    expect(outputFile.existsSync(), true,
        reason: 'Output PDF should be created');
    expect(outputFile.lengthSync(), greaterThan(0));
  }, timeout: const Timeout(Duration(seconds: 30)));

  group('mergeMultiplePDFs Integration Tests', () {
    testWidgets('Test merging two PDFs', (tester) async {
      final helper =
          TestFileHelper(['assets/document_1.pdf', 'assets/document_2.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
        outputPath: outputPath,
      );

      expect(result, '${TestFileHelper.basePath}/merged_output.pdf');
    }, timeout: Timeout.none);

    testWidgets('Test merging single PDF file', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      final result = await PdfCombiner.mergeMultiplePDFs(
        inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
        outputPath: outputPath,
      );

      expect(result, '${TestFileHelper.basePath}/merged_output.pdf');
    }, timeout: Timeout.none);

    testWidgets('Test merging with empty list', (tester) async {
      final helper = TestFileHelper([]);
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
          inputs: [],
          outputPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message == 'The parameter (inputs) cannot be empty',
          ),
        ),
      );
    }, timeout: Timeout.none);

    testWidgets('Test merging with non-existing file', (tester) async {
      final helper = TestFileHelper(['assets/document_1.pdf']);
      final inputPaths = await helper.prepareInputFiles();
      inputPaths.add('${TestFileHelper.basePath}/non_existing.pdf');
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
          inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
          outputPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message
                    .startsWith('File is not of PDF type or does not exist:'),
          ),
        ),
      );
    }, timeout: Timeout.none);

    testWidgets('Test merging with non-supported file', (tester) async {
      final helper =
          TestFileHelper(['assets/document_1.pdf', 'assets/image_1.jpeg']);
      final inputPaths = await helper.prepareInputFiles();
      final outputPath = await helper.getOutputFilePath('merged_output.pdf');

      expect(
        () => PdfCombiner.mergeMultiplePDFs(
          inputs: inputPaths.map((path) => MergeInput.path(path)).toList(),
          outputPath: outputPath,
        ),
        throwsA(
          predicate(
            (e) =>
                e is PdfCombinerException &&
                e.message
                    .startsWith('File is not of PDF type or does not exist:'),
          ),
        ),
      );
    });
  });
}
