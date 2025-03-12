import 'image_compression.dart';
import 'image_scale.dart';

/// Configuration for generating images from a PDF.
class ImageFromPdfConfig {
  /// The scale to apply to the images when generating the PDF.
  final ImageScale rescale;

  /// The image compression level for compression, affecting file size, quality and clarity.
  final ImageCompression compression;

  /// Indicates whether to create a single image or separate images for each page.
  final bool createOneImage;

  /// Creates an instance of [ImageFromPdfConfig].
  ///
  /// [rescale] allows specifying a scaling option for the images.
  /// [compression] sets the compression level for the images, affecting file size and quality, defaulting to [ImageCompression.none].
  /// [createOneImage] determines if a single image should be created or separate images for each page. Default is `false`.
  const ImageFromPdfConfig({
    ImageScale? rescale,
    this.compression = ImageCompression.none,
    this.createOneImage = false,
  }) : rescale = rescale ?? ImageScale.original;
}
