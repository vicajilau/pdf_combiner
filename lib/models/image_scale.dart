/// Represents an image scaling configuration with a specific width and height.
class ImageScale {
  /// The target width of the scaled image.
  final int width;

  /// The target height of the scaled image.
  final int height;

  /// Creates an instance of [ImageScale] with the given width and height.
  ///
  /// Asserts that [width] and [height] are non-negative.
  const ImageScale({required this.width, required this.height})
      : assert(width >= 0 && height >= 0,
            'width and height must be higher than 0');

  /// Factory constructor for representing the original image without scaling.
  ///
  /// This sets both width and height to `0`, indicating that no scaling is applied.
  static const original = ImageScale(width: 0, height: 0);

  /// Returns `true` if this instance represents the original image (no scaling).
  bool get isOriginal => width == 0 && height == 0;

  /// Creates a new [ImageScale] instance by applying a transformation function
  /// to the current width and height.
  ///
  /// The [mapper] function takes the current width and height as arguments
  /// and should return a new [ImageScale] instance.
  Map<String,dynamic> toMap() {
    return {
      'width': width, // Convert enum to string
      'height': height,
    };
  }
}
