## 4.1.2
### General
* Drag & Drop Capability added on example project.

## 4.1.1
### Android
* Fixed `createPDFFromMultipleImages` without configuration. [#35](https://github.com/vicajilau/pdf_combiner/issues/35)

## 4.1.0
### General
* Improved documentation.
### Linux
* Improved error management.
### Windows
* Added support with PDFium by Google with C++.

## 4.0.1
### General
* Refactored `pdf_combiner` to use `compute` for native calls (`MethodChannel`), reducing potential UI freezes (UI thread blocking).
* `isMock` has been added to `PdfCombiner` for testing purposes, when set to true, isolates will not be executed using main Isolate.

## 4.0.0
### General
* Errors are being recovered from native and sent through the message.
* New optional parameter `config` of type `PdfFromMultipleImageConfig` to the method `createPDFFromMultipleImages`.
* New optional parameter `config` of type `ImageFromPdfConfig` to the method `createImageFromPDF`.
* **BREAKING CHANGE:** `maxWidth`, `maxHeight` and `needImageCompressor` has been inserted inside of `config` property on `createPDFFromMultipleImages`method.
* **BREAKING CHANGE:** `maxWidth`, `maxHeight` and `createOneImage` has been inserted inside of `config` property on `createImageFromPDF`method.
* **BREAKING CHANGE:** `outputPath` parameter has been renamed by `outputDirPath` in `createImageFromPDF` method.
* **BREAKING CHANGE:** `createOneImage` is false by default in `createImageFromPDF` method.
### Android
* `Apache PDFBox` has been replaced by native code with `android.graphics`implementation.

## 3.4.0
### Linux
* Added support with PDFium by Google with C++.

## 3.3.0
### Web
* Removed the need for manually importing JavaScript files and modifying `index.html`. [#21](https://github.com/vicajilau/pdf_combiner/issues/21).

## 3.2.0
### General
* Error management improved.
* File type detection improved with `file_magic_number` dependency. [file_magic_number](https://github.com/vicajilau/file_magic_number)
* Universal flows improved.

## 3.1.2
### General
* Simplified catching errors.
* Added 100% coverage tests.

## 3.1.1
### General
* Added Codecov tool.
* Added coverage on CI and PRs.
### Android
* Fix issue with special characters in the `outputPath` param on `imageFromPDF` method.

## 3.1.0
### General
* Integrated CD.
### iOS
* iOS migration to SPM.
### MacOS
* MacOS migration to SPM.

## 3.0.4
### Web
* Fixed linting issues.
* WASP improvements.

## 3.0.3
### Web
* Some internal improvements.

## 3.0.2
### Web
* Added WASM support.

## 3.0.1
### General
* Fixed CI badge.
### Web
* js_utils migrated to js_interop.

## 3.0.0
### General
* Tooltips, theme, and more improvements on example project.
* Improved documentation inside of the code.
* Some improvements on the readme.
* Updated dependencies.
* Added more integration tests.
* Minimized code size.
* Minimized code size.
* Optimized CI/CD process.
### iOS
* Fixed wrong order exporting a pdf to one image [#9](https://github.com/vicajilau/pdf_combiner/issues/9).
* Refactor creating extensions.
### MacOS
* MacOS support added.
* Refactor creating extensions.
### Web
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
