import 'package:pdf_combiner/responses/pdf_combiner_status.dart';

class ImageFromPDFResponse {
  PdfCombinerStatus status;
  String? message;
  List<String?>? response;

  ImageFromPDFResponse(
      {this.status = PdfCombinerStatus.empty, this.response, this.message});
}
