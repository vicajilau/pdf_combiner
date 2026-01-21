import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdfCombinerPlatformWithError
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  @override
  Future<String?> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) {
    throw PdfCombinerException('error');
  }

  @override
  Future<String?> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    throw PdfCombinerException('error');
  }

  @override
  Future<List<String>?> createImageFromPDF({
    required MergeInput input,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    if (config.rescale == ImageScale.original) {
      throw PdfCombinerException('error');
    }
    return Future.value([]);
  }
}
