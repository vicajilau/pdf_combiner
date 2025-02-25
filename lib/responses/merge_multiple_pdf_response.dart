import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class MergeMultiplePDFResponse {
  String outputPath, message;
  PdfCombinerStatus status;

  MergeMultiplePDFResponse({
    required this.status,
    this.outputPath = "",
    required this.message,
  });

  @override
  String toString() =>
      "MergeMultiplePDFResponse{outputPath: $outputPath, message: $message, status: $status }";
}
