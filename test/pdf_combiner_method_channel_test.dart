import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPdfCombiner platform = MethodChannelPdfCombiner();
  const MethodChannel channel = MethodChannel('pdf_combiner');

  setUp(() {
    // Mock method call handler for testing platform methods.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'mergeMultiplePDF') {
          // Simulate a successful merge and return a dummy result.
          return 'Merge successful';
        } else if (methodCall.method == 'createImageFromPDF') {
          // Simulate a successful merge and return a dummy result.
          return ['Merge successful'];
        } else if (methodCall.method == 'createPDFFromMultipleImage') {
          // Simulate a successful merge and return a dummy result.
          return 'Merge successful';
        }
        return null;
      },
    );
  });

  tearDown(() {
    // Clean up the mock after each test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MethodChannelPdfCombiner Unit Tests', () {
    test('mergeMultiplePDF returns success message', () async {
      // Arrange
      List<String> paths = ['file1.pdf', 'file2.pdf'];
      String outputDirPath = '/path/to/output/';

      // Act
      final result = await platform.mergeMultiplePDFs(
        inputPaths: paths,
        outputPath: outputDirPath,
      );

      // Assert
      expect(result, 'Merge successful');
    });

    test('createImageFromPDF returns success message', () async {
      // Arrange
      String path = 'file1.pdf';
      String outputDirPath = '/path/to/output/';

      // Act
      final result = await platform.createImageFromPDF(
        inputPath: path,
        outputPath: outputDirPath,
      );

      // Assert
      expect(result, ['Merge successful']);
    });

    test('createPDFFromMultipleImages returns success message', () async {
      // Arrange
      List<String> paths = ['file1.jpg', 'file2.png'];
      String outputDirPath = '/path/to/output/';

      // Act
      final result = await platform.createPDFFromMultipleImages(
        inputPaths: paths,
        outputPath: outputDirPath,
      );

      // Assert
      expect(result, 'Merge successful');
    });
  });
}
