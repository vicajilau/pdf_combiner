export 'package:pdf_combiner/utils/document_utils_base.dart'
    if (dart.library.io) 'package:pdf_combiner/utils/document_utils_io.dart'
    if (dart.library.html) 'package:pdf_combiner/web/document_utils_web.dart';
