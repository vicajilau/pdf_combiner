
import '../communication/status.dart';

class MergeMultiplePDFResponse {
  String? status, response, message;

  MergeMultiplePDFResponse(
      {this.status = Status.empty, this.response, this.message});
}