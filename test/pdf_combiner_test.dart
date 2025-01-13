import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/pdf_combiner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdfCombinerPlatform
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PdfCombinerPlatform initialPlatform = PdfCombinerPlatform.instance;

  test('$MethodChannelPdfCombiner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPdfCombiner>());
  });

  test('getPlatformVersion', () async {
    PdfCombiner pdfCombinerPlugin = PdfCombiner();
    MockPdfCombinerPlatform fakePlatform = MockPdfCombinerPlatform();
    PdfCombinerPlatform.instance = fakePlatform;

    expect(await pdfCombinerPlugin.getPlatformVersion(), '42');
  });
}
