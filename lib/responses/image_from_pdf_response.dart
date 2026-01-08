/// Represents the response for extracting images from a PDF file.
class ImageFromPDFResponse {
  /// An optional message providing additional details about the process.
  String? message;

  /// A list of file paths where the extracted images are saved.
  List<String> outputPaths;

  /// Creates a response object for image extraction from a PDF.
  ///
  /// - [outputPaths] A list of file paths for the extracted images (defaults to an empty list).
  /// - [message] An optional message with additional information.
  ImageFromPDFResponse({
    this.outputPaths = const [],
    this.message,
  });

  @override
  String toString() =>
      "ImageFromPDFResponse{outputPaths: $outputPaths, message: $message}";
}
