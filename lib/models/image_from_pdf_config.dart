import 'package:pdf_combiner/models/image_quality.dart';

import 'image_scale.dart';

/// Configuration for generating images from a PDF.
class ImageFromPdfConfig {
  /// The scale to apply to the images when generating the PDF.
  final ImageScale rescale;

  /// The image quality level for compression, affecting file size and clarity.
  final ImageQuality compression;

  /// Indicates whether to create a single image or separate images for each page.
  final bool createOneImage;

  /// Creates an instance of [ImageFromPdfConfig].
  ///
  /// [rescale] allows specifying a scaling option for the images.
  /// [compression] sets the quality level for the images, defaulting to [ImageQuality.high].
  /// [createOneImage] determines if a single image should be created or separate images for each page. Default is `false`.
  const ImageFromPdfConfig({
    ImageScale? rescale,
    this.compression = ImageQuality.high,
    this.createOneImage = false,
  }) : rescale = rescale ?? ImageScale.original;
}
