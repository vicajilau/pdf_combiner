import '../communication/pdf_combiner_status.dart';

class PdfFromMultipleImageResponse {
  PdfCombinerStatus status;
  String? response, message;

  PdfFromMultipleImageResponse(
      {this.status = PdfCombinerStatus.empty, this.response, this.message});
}
