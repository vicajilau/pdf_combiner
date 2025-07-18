/// Represents the compression level of an image, which affects quality and file size.
class ImageCompression {
  /// The compression value, typically ranging from 0 to 99.
  final int value;

  /// Private constructor to enforce controlled instantiation.
  ///
  /// Asserts that [value] is between 0 and 100.
  const ImageCompression._(this.value)
      : assert(
            value >= 0 && value <= 100, 'Quality must be between 0 and 100.');

  /// No compression, with highest quality and largest file size.
  static const none = _FixedImageCompression(0);

  /// Low image compression, with higher quality and larger file size.
  static const low = _FixedImageCompression(30);

  /// Medium image compression, balancing quality and image clarity.
  static const medium = _FixedImageCompression(60);

  /// High image compression, with minimal quality and smaller file size.
  static const high = _FixedImageCompression(100);

  /// Creates a custom image quality level with a specified value.
  ///
  /// The [value] must be between 0 and 100.
  factory ImageCompression.custom(int value) {
    return _CustomImageCompression(value);
  }
}

/// Represents a predefined, fixed image compression level.
class _FixedImageCompression extends ImageCompression {
  /// Creates an instance of [_FixedImageCompression] with a predefined value.
  const _FixedImageCompression(super.value) : super._();
}

/// Represents a user-defined custom image compression level.
class _CustomImageCompression extends ImageCompression {
  /// Creates an instance of [_CustomImageCompression] with a specified value.
  _CustomImageCompression(super.value) : super._();
}
