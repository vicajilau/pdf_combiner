import 'package:pdf_combiner/models/image_quality.dart';

import 'image_scale.dart';

/// Configuration for generating a PDF from multiple images.
class PdfFromMultipleImageConfig {
  /// The scale to apply to the images when generating the PDF.
  final ImageScale rescale;

  /// The image quality level for compression, affecting file size and clarity.
  final ImageQuality compression;

  /// Indicates whether to maintain the aspect ratio of the images.
  final bool keepAspectRatio;

  /// Creates an instance of [PdfFromMultipleImageConfig].
  ///
  /// [rescale] allows specifying a scaling option for the images.
  /// [compression] sets the quality level for the images, defaulting to [ImageQuality.high].
  /// [keepAspectRatio] determines if the aspect ratio should be preserved, defaulting to `true`.
  const PdfFromMultipleImageConfig({
    ImageScale? rescale,
    this.compression = ImageQuality.high,
    this.keepAspectRatio = true,
  }): rescale = rescale ?? ImageScale.original;
}
