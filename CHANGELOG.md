## 3.0.0

* Tooltips, theme, and more improvements on example project.
* Improved documentation inside of the code.
* MacOS support added.
* Web support added.

## 2.1.0

* Added support for empty images.
* Errors are more explicits adding the path.
* Bugfix when file does not exist. See [#3](https://github.com/vicajilau/pdf_combiner/issues/3) for details.
* Added more unit testing.
* Updated Android dependencies.

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
* BREAKING CHANGE: response.status is not a String anymore, now it is a PdfCombinerStatus enum value.
* Added more tests.
* Improved documentation.

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
