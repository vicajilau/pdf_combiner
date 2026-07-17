/// Represents the compression level of an image, which affects quality and file size.
class ImageCompression {
  /// The compression value, typically ranging from 0 to 100.
  final int value;

  /// Private constructor to enforce controlled instantiation for fixed levels.
  const ImageCompression._(this.value);

  /// Creates a custom image quality level with a specified value.
  ///
  /// The [value] must be between 0 and 100.
  const ImageCompression.custom(this.value)
      : assert(value >= 0 && value <= 100, 'Quality must be between 0 and 100.');

  /// No compression, with highest quality and largest file size.
  static const none = ImageCompression._(0);

  /// Low image compression, with higher quality and larger file size.
  static const low = ImageCompression._(30);

  /// Medium image compression, balancing quality and image clarity.
  static const medium = ImageCompression._(60);

  /// High image compression, with minimal quality and smaller file size.
  static const high = ImageCompression._(100);
}
