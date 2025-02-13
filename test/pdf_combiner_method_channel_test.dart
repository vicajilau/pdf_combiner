import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mocks/mock_pdf_combiner_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MockPdfCombinerPlatform platform = MockPdfCombinerPlatform();
  const MethodChannel channel = MethodChannel('pdf_combiner');

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
      expect(result, 'Merged PDF');
    });

    test('createImageFromPDF returns success message with some images', () async {
      // Arrange
      String path = 'file1.pdf';
      String outputDirPath = '/path/to/output/';

      // Act
      final List<String>? result = await platform.createImageFromPDF(
        inputPath: path,
        outputPath: outputDirPath,
          createOneImage: false
      );

      // Assert
      expect(result, ['image1.png', 'image2.png']);
    });

    test('createImageFromPDF returns success message only in one image', () async {
      // Arrange
      String path = 'file1.pdf';
      String outputDirPath = '/path/to/output/';

      // Act
      final List<String>? result = await platform.createImageFromPDF(
        inputPath: path,
        outputPath: outputDirPath,
        createOneImage: true
      );

      // Assert
      expect(result, ['image1.png']);
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
      expect(result, 'Created PDF from Images');
    });
  });
}
