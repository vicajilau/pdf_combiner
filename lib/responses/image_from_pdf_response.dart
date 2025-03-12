import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

/// Represents the response for extracting images from a PDF file.
class ImageFromPDFResponse {
  /// The status of the image extraction process.
  PdfCombinerStatus status;

  /// An optional message providing additional details about the process.
  String? message;

  /// A list of file paths where the extracted images are saved.
  List<String> outputPaths;

  /// Creates a response object for image extraction from a PDF.
  ///
  /// - [status] The status of the extraction process (required).
  /// - [outputPaths] A list of file paths for the extracted images (defaults to an empty list).
  /// - [message] An optional message with additional information.
  ImageFromPDFResponse({
    required this.status,
    this.outputPaths = const [],
    this.message,
  });

  @override
  String toString() =>
      "ImageFromPDFResponse{outputPaths: $outputPaths, message: $message, status: $status }";
}
