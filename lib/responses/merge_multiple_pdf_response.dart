import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class MergeMultiplePDFResponse {
  String outputPath, message;
  PdfCombinerStatus status;

  MergeMultiplePDFResponse(
      {this.status = PdfCombinerStatus.empty,
      this.outputPath = "",
      required this.message});

  @override
  String toString() =>
      "MergeMultiplePDFResponse{outputPath: $outputPath, message: $message, status: $status }";
}
