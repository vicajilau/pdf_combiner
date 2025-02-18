import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('pdf_combiner');
  final MethodChannelPdfCombiner platform = MethodChannelPdfCombiner();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'mergeMultiplePDF':
          return 'Merged PDF';
        case 'createImageFromPDF':
          return methodCall.arguments['createOneImage'] == true
              ? ['image1.png']
              : ['image1.png', 'image2.png'];
        case 'createPDFFromMultipleImage':
          return 'Created PDF from Images';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelPdfCombiner Unit Tests', () {
    test('mergeMultiplePDF returns success message', () async {
      final result = await platform.mergeMultiplePDFs(
        inputPaths: ['file1.pdf', 'file2.pdf'],
        outputPath: '/path/to/output/',
      );
      expect(result, 'Merged PDF');
    });

    test('createImageFromPDF returns success message with multiple images',
        () async {
      final result = await platform.createImageFromPDF(
        inputPath: 'file1.pdf',
        outputPath: '/path/to/output/',
        createOneImage: false,
      );
      expect(result, ['image1.png', 'image2.png']);
    });

    test('createImageFromPDF returns success message with a single image',
        () async {
      final result = await platform.createImageFromPDF(
        inputPath: 'file1.pdf',
        outputPath: '/path/to/output/',
        createOneImage: true,
      );
      expect(result, ['image1.png']);
    });

    test('createPDFFromMultipleImages returns success message', () async {
      final result = await platform.createPDFFromMultipleImages(
        inputPaths: ['file1.jpg', 'file2.png'],
        outputPath: '/path/to/output/',
      );
      expect(result, 'Created PDF from Images');
    });
  });
}
