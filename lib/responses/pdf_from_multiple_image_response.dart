import '../communication/status.dart';

class PdfFromMultipleImageResponse {
  String? status, response, message;

  PdfFromMultipleImageResponse(
      {this.status = Status.empty, this.response, this.message});
}
