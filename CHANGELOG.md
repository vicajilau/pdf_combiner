## 2.0.0

* BREAKING CHANGE: mergeMultiplePDF has been renamed by mergeMultiplePDFs.
* BREAKING CHANGE: createPDFFromMultipleImage has been renamed by createPDFFromMultipleImages.
* BREAKING CHANGE: createImageFromPDF has been renamed by createImageFromPDFs.
* BREAKING CHANGE: `paths` parameter has been renamed by `inputPaths` in mergeMultiplePDFs method.
* BREAKING CHANGE: `outputDirPath` parameter has been renamed by `outputPath` in mergeMultiplePDFs method.
* BREAKING CHANGE: `paths` parameter has been renamed by `inputPaths` in mergeMultiplePDFs method.
* BREAKING CHANGE: `outputDirPath` parameter has been renamed by `outputPath` in createPDFFromMultipleImages method.
* BREAKING CHANGE: `path` parameter has been renamed by `inputPath` in createPDFFromMultipleImages method.
* BREAKING CHANGE: `outputDirPath` parameter has been renamed by `outputPath` in createImageFromPDF method.

## 1.0.1

* Updated min SDK of Dart to 3.0
* Updated min SDK of Flutter to 3.0

## 1.0.0

* Initial release of the PDF Combiner package.
* Allows users to select multiple PDF files.
* Combines selected PDFs into a single output file.
* Supports storage permissions on Android for file access.
* Displays success and error messages using SnackBars.
* Provides compatibility with both Android and iOS platforms for saving the output file.
* Completed migration from pdf_merger.
