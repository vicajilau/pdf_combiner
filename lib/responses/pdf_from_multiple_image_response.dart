import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class PdfFromMultipleImageResponse {
  PdfCombinerStatus status;
  String? response, message;

  PdfFromMultipleImageResponse(
      {this.status = PdfCombinerStatus.empty, this.response, this.message});

  @override
  String toString() =>
      "PdfFromMultipleImageResponse{response: $response, message: $message, status: $status }";
}
