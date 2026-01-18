import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel testChannel = MethodChannel('pdf_combiner');
  group('PdfCombiner', () {
    test("test one image and one pdf", () async {
      PdfCombiner.isMock = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'createPDFFromMultipleImage' ||
            methodCall.method == 'mergeMultiplePDF') {
          return './example/assets/temp/document_0.pdf';
        }
        return null;
      });
      DocumentUtils.setTemporalFolderPath("./example/assets/temp");
      var result = await PdfCombiner.generatePDFFromDocuments(
        inputs: [MergeInputPath("./example/assets/image_1.jpeg")],
        outputPath: "./example/assets/temp/document_0.pdf",
      );
      expect(result, "./example/assets/temp/document_0.pdf");
    });
  });
}
