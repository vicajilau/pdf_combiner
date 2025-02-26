/// Represents an image scaling configuration with a specific width and height.
class ImageScale {
  /// The target width of the scaled image.
  final int width;

  /// The target height of the scaled image.
  final int height;

  /// Creates an instance of [ImageScale] with the given width and height.
  const ImageScale({required this.width, required this.height})
      : assert(width >= 0 && height >= 0,
            'width and height must be higher than 0');

  /// Factory constructor for representing the original image without scaling.
  ///
  /// This sets both width and height to `0`, indicating that no scaling is applied.
  static const original = ImageScale(width: 0, height: 0);

  /// Returns `true` if this instance represents the original image (no scaling).
  bool get isOriginal => width == 0 && height == 0;
}