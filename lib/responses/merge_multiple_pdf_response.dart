import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

/// Represents the response for merging multiple PDF files into a single document.
class MergeMultiplePDFResponse {
  /// The file path where the merged PDF is saved.
  String outputPath;

  /// A message providing additional details about the merging process.
  String message;

  /// The status of the PDF merging process.
  PdfCombinerStatus status;

  /// Creates a response object for merging multiple PDFs.
  ///
  /// - [status] The status of the merging process (required).
  /// - [outputPath] The path of the merged PDF file (defaults to an empty string).
  /// - [message] Additional information about the operation (required).
  MergeMultiplePDFResponse({
    required this.status,
    this.outputPath = "",
    required this.message,
  });

  @override
  String toString() =>
      "MergeMultiplePDFResponse{outputPath: $outputPath, message: $message, status: $status }";
}
