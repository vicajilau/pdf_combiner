import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class GeneratePdfFromDocumentsResponse {
  String outputPath, message;
  PdfCombinerStatus status;

  GeneratePdfFromDocumentsResponse({
    required this.status,
    this.outputPath = "",
    required this.message,
  });

  @override
  String toString() =>
      "GeneratePdfFromDocumentsResponse{outputPath: $outputPath, message: $message, status: $status }";
}
