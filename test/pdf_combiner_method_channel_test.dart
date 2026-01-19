import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MethodChannelPdfCombiner platform;
  const MethodChannel testChannel = MethodChannel('pdf_combiner');

  setUp(() {
    platform = MethodChannelPdfCombiner();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, null);
  });

  test('mergeMultiplePDFs calls method channel correctly with path', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'mergeMultiplePDF') {
        expect(methodCall.arguments, {
          'paths': ['file1.pdf', 'file2.pdf'],
          'outputDirPath': '/output/path',
        });
        return 'merged.pdf';
      }
      return null;
    });

    final result = await platform.mergeMultiplePDFs(
      inputs: [MergeInput.path('file1.pdf'), MergeInput.path('file2.pdf')],
      outputPath: '/output/path',
    );

    expect(result, 'merged.pdf');
  });

  test('mergeMultiplePDFs handles MergeInput.bytes correctly', () async {
    final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
    final tempPath =
        "${DocumentUtils.getTemporalFolderPath()}/temp_pdf_merge_0.pdf";

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'mergeMultiplePDF') {
        final paths = methodCall.arguments['paths'] as List;
        expect(paths.length, 1);
        expect(paths[0], tempPath);
        return 'merged.pdf';
      }
      return null;
    });

    final result = await platform.mergeMultiplePDFs(
      inputs: [MergeInput.bytes(pdfBytes)],
      outputPath: '/output/path',
    );

    expect(result, 'merged.pdf');

    // Clean up temp file
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  });

  test('createPDFFromMultipleImages calls method channel correctly', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'createPDFFromMultipleImage') {
        expect(methodCall.arguments, {
          'paths': ['image1.jpg', 'image2.png'],
          'outputDirPath': '/output/path',
          'height': 0,
          'width': 0,
          'keepAspectRatio': true
        });
        return 'created.pdf';
      }
      return null;
    });

    final result = await platform.createPDFFromMultipleImages(
      inputs: [MergeInput.path('image1.jpg'), MergeInput.path('image2.png')],
      outputPath: '/output/path',
    );

    expect(result, 'created.pdf');
  });

  test('createImageFromPDF calls method channel correctly', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'createImageFromPDF') {
        expect(methodCall.arguments, {
          'path': 'file.pdf',
          'outputDirPath': '/output/path',
          'height': 400,
          'width': 400,
          'compression': 0,
          'createOneImage': false
        });
        return ['image1.png', 'image2.png'];
      }
      return null;
    });

    final result = await platform.createImageFromPDF(
      input: MergeInput.path('file.pdf'),
      outputPath: '/output/path',
      config: ImageFromPdfConfig(
          rescale: ImageScale(width: 400, height: 400), createOneImage: false),
    );

    expect(result, ['image1.png', 'image2.png']);
  });
}
