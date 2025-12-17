
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/pdf_combiner_delegate.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
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
          inputPaths: ["./example/assets/image_1.jpeg"],
          outputPath: "./example/assets/temp/document_0.pdf",
          delegate: PdfCombinerDelegate());
      expect(result.status, PdfCombinerStatus.success);
      expect(result.outputPath, "./example/assets/temp/document_0.pdf");
    });

    test("generatePDFFromDocuments with Uint8List input", () async {
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

      final imageFile = File("./example/assets/image_1.jpeg");
      final Uint8List bytes = await imageFile.readAsBytes();

      var result = await PdfCombiner.generatePDFFromDocuments(
          inputPaths: [bytes],
          outputPath: "./example/assets/temp/document_0.pdf",
          delegate: PdfCombinerDelegate());

      expect(result.status, PdfCombinerStatus.success);
      expect(result.outputPath, "./example/assets/temp/document_0.pdf");
    });

    test("generatePDFFromDocuments with null input paths", () async {
      var result = await PdfCombiner.generatePDFFromDocuments(
          inputPaths: null,
          outputPath: "./example/assets/temp/document_0.pdf",
          delegate: PdfCombinerDelegate());
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, PdfCombinerMessages.emptyParameterMessage("inputs"));
    });

    test("generatePDFFromDocuments with empty input paths", () async {
      var result = await PdfCombiner.generatePDFFromDocuments(
          inputPaths: [],
          outputPath: "./example/assets/temp/document_0.pdf",
          delegate: PdfCombinerDelegate());
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, PdfCombinerMessages.emptyParameterMessage("inputs"));
    });

    test("generatePDFFromDocuments with empty output path", () async {
      var result = await PdfCombiner.generatePDFFromDocuments(
          inputPaths: ["./example/assets/image_1.jpeg"],
          outputPath: "",
          delegate: PdfCombinerDelegate());
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message, PdfCombinerMessages.emptyParameterMessage("outputPath"));
    });

    test("generatePDFFromDocuments with invalid output path", () async {
      var result = await PdfCombiner.generatePDFFromDocuments(
          inputPaths: ["./example/assets/image_1.jpeg"],
          outputPath: "./example/assets/temp/document_0",
          delegate: PdfCombinerDelegate());
      expect(result.status, PdfCombinerStatus.error);
      expect(result.message,
          PdfCombinerMessages.errorMessageInvalidOutputPath("./example/assets/temp/document_0"));
    });
  });
}
