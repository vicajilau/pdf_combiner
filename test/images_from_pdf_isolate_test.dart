import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:pdf_combiner/isolates/merge_pdfs_isolate.dart';
import 'package:pdf_combiner/isolates/pdf_from_multiple_images_isolate.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';

void main() {
  group('ImagesFromPdfIsolate Unit Tests', () {
    test('ImagesFromPdfIsolate', () async {
      // Call the method and check the response.
      expect(
        () async => await ImagesFromPdfIsolate.createImageFromPDF(
            inputPath: 'example/assets/document_1.pdf',
            outputDirectory: 'output/',
            config: ImageFromPdfConfig()),
        throwsA(isA<Error>()),
      );
    });

    test('MergePdfsIsolate', () async {
      // Call the method and check the response.
      expect(
        () async => await MergePdfsIsolate.mergeMultiplePDFs(
            inputPaths: ['example/assets/document_1.pdf'],
            outputPath: 'output/'),
        throwsA(isA<Error>()),
      );
    });

    test('PdfFromMultipleImagesIsolate', () async {
      // Call the method and check the response.
      expect(
        () async =>
            await PdfFromMultipleImagesIsolate.createPDFFromMultipleImages(
                inputPaths: ['example/assets/document_1.pdf'],
                outputPath: 'output/output.pdf',
                config: PdfFromMultipleImageConfig()),
        throwsA(isA<Error>()),
      );
    });
  });
}
