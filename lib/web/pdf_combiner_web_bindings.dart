import 'dart:js_interop';

/// **JavaScript binding to combine multiple PDFs**
/// This external function calls the `combinePDFs` JavaScript function, passing a `JSArray<JSString>` of input file paths.
/// It returns a `JSPromise` which resolves to the result of combining the PDFs.
@JS('combinePDFs')
external JSPromise combinePDFs(JSArray<JSString> inputPaths);

/// **JavaScript binding to create a PDF from multiple images**
/// This external function calls the `createPdfFromImages` JavaScript function, passing a `JSArray<JSString>` of input image file paths.
/// It returns a `JSPromise` which resolves to the path of the created PDF.
@JS('createPdfFromImages')
external JSPromise createPdfFromImages(JSArray<JSString> inputPaths);

/// **JavaScript binding to convert a PDF to a single image**
/// This external function calls the `pdfToImage` JavaScript function, passing a `JSString` input path of the PDF file.
/// It returns a `JSPromise` which resolves to the resulting image.
@JS('pdfToImage')
external JSPromise pdfToImage(JSString inputPath);

/// **JavaScript binding to convert a PDF to multiple images**
/// This external function calls the `convertPdfToImages` JavaScript function, passing a `JSString` input path of the PDF file.
/// It returns a `JSPromise` which resolves to the resulting images.
@JS('convertPdfToImages')
external JSPromise convertPdfToImages(JSString inputPath);
