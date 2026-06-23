import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:pdf_combiner/isolates/merge_pdfs_isolate.dart';
import 'package:pdf_combiner/isolates/pdf_from_multiple_images_isolate.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdfCombinerPlatform extends PdfCombinerPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> mergeMultiplePDFs(
          {required List<MergeInput> inputs, required String outputPath}) =>
      Future.value(outputPath);

  @override
  Future<String?> createPDFFromMultipleImages(
          {required List<MergeInput> inputs,
          required String outputPath,
          PdfFromMultipleImageConfig config =
              const PdfFromMultipleImageConfig()}) =>
      Future.value(outputPath);

  @override
  Future<List<String>?> createImageFromPDF(
          {required MergeInput input,
          required String outputPath,
          ImageFromPdfConfig config = const ImageFromPdfConfig()}) =>
      Future.value([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImagesFromPdfIsolate Unit Tests', () {
    setUp(() {
      PdfCombiner.isMock = true;
      PdfCombinerPlatform.instance = MockPdfCombinerPlatform();
    });

    test('ImagesFromPdfIsolate', () async {
      final result = await ImagesFromPdfIsolate.createImageFromPDF(
          inputPath: 'example/assets/document_1.pdf',
          outputDirectory: 'output/',
          config: const ImageFromPdfConfig());
      expect(result, isA<List<String>?>());
    });

    test('MergePdfsIsolate returns error message for invalid output path',
        () async {
      final result = await MergePdfsIsolate.mergeMultiplePDFs(
          inputs: [MergeInput.path('example/assets/document_1.pdf')],
          outputPath: 'output/');
      expect(result,
          PdfCombinerMessages.errorMessageInvalidOutputPath('output/'));
    });

    test('PdfFromMultipleImagesIsolate', () async {
      final result =
          await PdfFromMultipleImagesIsolate.createPDFFromMultipleImages(
              inputPaths: ['example/assets/document_1.pdf'],
              outputPath: 'output/output.pdf',
              config: const PdfFromMultipleImageConfig());
      expect(result, 'output/output.pdf');
    });

    test('PdfFromMultipleImageConfig test map has same values as config',
        () async {
      const config = PdfFromMultipleImageConfig(
          rescale: ImageScale(width: 400, height: 400), keepAspectRatio: false);
      final Map<String, dynamic> expectedMap = {
        'rescale': {
          'width': 400,
          'height': 400,
        },
        'keepAspectRatio': false
      };
      expect(
        config.toMap(),
        expectedMap,
      );
    });
  });
}
