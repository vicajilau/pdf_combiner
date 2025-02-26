/// Represents the quality level of an image, which affects compression and file size.
sealed class ImageQuality {
  /// The quality value, typically ranging from 0 to 100.
  final int value;

  /// Private constructor to enforce controlled instantiation.
  ///
  /// Asserts that [value] is between 1 and 100.
  const ImageQuality._(this.value)
      : assert(value > 0 && value <= 100, 'Quality must be between 1 and 100.');

  /// Low image quality, with higher compression and smaller file size.
  static const low = _FixedImageQuality(30);

  /// Medium image quality, balancing compression and image clarity.
  static const medium = _FixedImageQuality(60);

  /// High image quality, with minimal compression and larger file size.
  static const high = _FixedImageQuality(100);

  /// Creates a custom image quality level with a specified value.
  ///
  /// The [value] must be between 1 and 100.
  factory ImageQuality.custom(int value) {
    return _CustomImageQuality(value);
  }
}

/// Represents a predefined, fixed image quality level.
class _FixedImageQuality extends ImageQuality {
  /// Creates an instance of [_FixedImageQuality] with a predefined value.
  const _FixedImageQuality(super.value) : super._();
}

/// Represents a user-defined custom image quality level.
class _CustomImageQuality extends ImageQuality {
  /// Creates an instance of [_CustomImageQuality] with a specified value.
  _CustomImageQuality(super.value) : super._();
}
