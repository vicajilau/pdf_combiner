/// Represents the response for merging multiple PDF files into a single document.
class MergeMultiplePDFResponse {
  /// The file path where the merged PDF is saved.
  String outputPath;

  /// A message providing additional details about the merging process.
  String message;

  /// Creates a response object for merging multiple PDFs.
  ///
  /// - [outputPath] The path of the merged PDF file (defaults to an empty string).
  /// - [message] Additional information about the operation (required).
  MergeMultiplePDFResponse({
    this.outputPath = "",
    required this.message,
  });

  @override
  String toString() =>
      "MergeMultiplePDFResponse{outputPath: $outputPath, message: $message}";
}
