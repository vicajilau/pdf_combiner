import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';

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

  test('mergeMultiplePDFs calls method channel correctly', () async {
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
      inputPaths: ['file1.pdf', 'file2.pdf'],
      outputPath: '/output/path',
    );

    expect(result, 'merged.pdf');
  });

  test('createPDFFromMultipleImages calls method channel correctly', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(testChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'createPDFFromMultipleImage') {
        expect(methodCall.arguments, {
          'paths': ['image1.jpg', 'image2.png'],
          'outputDirPath': '/output/path',
          'maxWidth': 500,
          'maxHeight': 500,
          'needImageCompressor': false,
        });
        return 'created.pdf';
      }
      return null;
    });

    final result = await platform.createPDFFromMultipleImages(
      inputPaths: ['image1.jpg', 'image2.png'],
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
          'maxWidth': 400,
          'maxHeight': 400,
          'createOneImage': false,
        });
        return ['image1.png', 'image2.png'];
      }
      return null;
    });

    final result = await platform.createImageFromPDF(
      inputPath: 'file.pdf',
      outputPath: '/output/path',
      maxWidth: 400,
      maxHeight: 400,
      createOneImage: false,
    );

    expect(result, ['image1.png', 'image2.png']);
  });
}
