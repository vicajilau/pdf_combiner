import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel testChannel = MethodChannel('pdf_combiner');
  group('PdfCombiner', () {
    test("test one image and one pdf", () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'createPDFFromMultipleImage') {
          return '/example/assets/temp/document_1.pdf';
        }
        return null;
      });
      PdfCombiner.isMock = true;
      DocumentUtils.temporalDir = "/example/assets/temp";
      var result = await PdfCombiner.createPdfFromImage("example/assets/image_1.jpeg",1);
      expect(result.status, PdfCombinerStatus.success);
      expect(result.outputPath, "/example/assets/temp/document_1.pdf");
    });
  });
}
