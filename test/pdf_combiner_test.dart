import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdfCombinerPlatform
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {

  @override
  Future<List<String>?> createImageFromPDF({required String inputPath, required String outputPath, int? maxWidth, int? maxHeight, bool? createOneImage}) {
    return Future.value([]);
  }

  @override
  Future<String?> createPDFFromMultipleImages({required List<String> inputPaths, required String outputPath, int? maxWidth, int? maxHeight, bool? needImageCompressor}) {
    // TODO: implement createPDFFromMultipleImages
    return Future.value("");
  }

  @override
  Future<String?> mergeMultiplePDFs({required List<String> inputPaths, required String outputPath}) {
    // TODO: implement mergeMultiplePDFs
    return Future.value("");
  }
}

void main() {
  final PdfCombinerPlatform initialPlatform = PdfCombinerPlatform.instance;

  test('$MethodChannelPdfCombiner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPdfCombiner>());
  });

  /*test('getPlatformVersion', () async {
    PdfCombiner pdfCombinerPlugin = PdfCombiner();
    MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
    PdfCombinerPlatform.instance = fakePlatform;

    expect(await pdfCombinerPlugin.getPlatformVersion(), '42');
  });*/
}
