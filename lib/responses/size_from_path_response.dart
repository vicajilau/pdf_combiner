import 'package:pdf_combiner/responses/status.dart';

class SizeFromPathResponse {
  String? status, message, response;

  SizeFromPathResponse(
      {this.status = Status.empty, this.response, this.message});
}
