import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class MergeMultiplePDFResponse {
  String? response, message;
  PdfCombinerStatus status;

  MergeMultiplePDFResponse(
      {this.status = PdfCombinerStatus.empty, this.response, this.message});

  @override
  String toString() =>
      "MergeMultiplePDFResponse{response: $response, message: $message, status: $status }";
}
