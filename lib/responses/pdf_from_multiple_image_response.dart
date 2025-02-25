import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class PdfFromMultipleImageResponse {
  PdfCombinerStatus status;
  String outputPath;
  String? message;

  PdfFromMultipleImageResponse({
    required this.status,
    this.outputPath = "",
    this.message,
  });

  @override
  String toString() =>
      "PdfFromMultipleImageResponse{outputPath: $outputPath, message: $message, status: $status }";
}
