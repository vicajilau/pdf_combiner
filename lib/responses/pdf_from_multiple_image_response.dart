/// Represents the response for creating a PDF from multiple images.
class PdfFromMultipleImageResponse {
  /// The file path where the generated PDF is saved.
  String outputPath;

  /// An optional message providing additional details about the process.
  String? message;

  /// Creates a response object for generating a PDF from multiple images.
  ///
  /// - [outputPath] The path of the generated PDF file (defaults to an empty string).
  /// - [message] An optional message with additional information.
  PdfFromMultipleImageResponse({
    this.outputPath = "",
    this.message,
  });

  @override
  String toString() =>
      "PdfFromMultipleImageResponse{outputPath: $outputPath, message: $message}";
}
