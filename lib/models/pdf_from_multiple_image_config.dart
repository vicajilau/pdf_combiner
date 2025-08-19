import 'image_scale.dart';

/// Configuration for generating a PDF from multiple images.
class PdfFromMultipleImageConfig {
  /// The scale to apply to the images when generating the PDF.
  final ImageScale rescale;

  /// Indicates whether to maintain the aspect ratio of the images.
  final bool keepAspectRatio;

  /// Creates an instance of [PdfFromMultipleImageConfig].
  ///
  /// [rescale] allows specifying a scaling option for the images, defaulting to `ImageScale.original`.
  /// [keepAspectRatio] determines if the aspect ratio should be preserved, defaulting to `true`.
  const PdfFromMultipleImageConfig({
    this.rescale = ImageScale.original,
    this.keepAspectRatio = true,
  });

  /// Converts this [PdfFromMultipleImageConfig] instance to a [Map<String, dynamic>].
  Map<String, dynamic> toMap() {
    return {
      'rescale': rescale.toMap(), // Convert enum to map
      'keepAspectRatio': keepAspectRatio,
    };
  }
}
