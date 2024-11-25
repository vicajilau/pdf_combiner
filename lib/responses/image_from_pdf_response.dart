import 'package:pdf_combiner/responses/status.dart';

class ImageFromPDFResponse {
  String? status, message;
  List<String?>? response;

  ImageFromPDFResponse(
      {this.status = Status.empty, this.response, this.message});
}
