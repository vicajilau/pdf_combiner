/// Represents the response for generating a PDF from multiple documents.
class GeneratePdfFromDocumentsResponse {
  /// The file path where the generated PDF is saved.
  String outputPath;

  /// A message providing additional details about the process.
  String message;

  /// Creates a response object for PDF generation.
  ///
  /// - [outputPath] The path of the generated PDF file (defaults to an empty string).
  /// - [message] Additional information about the operation (required).
  GeneratePdfFromDocumentsResponse({
    this.outputPath = "",
    required this.message,
  });

  @override
  String toString() =>
      "GeneratePdfFromDocumentsResponse{outputPath: $outputPath, message: $message}";
}
