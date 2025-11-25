import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/pdf_combiner_delegate.dart';
import 'package:pdf_combiner_example/utils/uint8list_extension.dart';
import 'package:pdf_combiner_example/views/widgets/file_type_icon.dart';

import '../view_models/pdf_combiner_view_model.dart';

class PdfCombinerScreen extends StatefulWidget {
  const PdfCombinerScreen({super.key});

  @override
  State<PdfCombinerScreen> createState() => _PdfCombinerScreenState();
}

class _PdfCombinerScreenState extends State<PdfCombinerScreen> {
  final PdfCombinerViewModel _viewModel = PdfCombinerViewModel();
  double _progress = 0.0;
  late PdfCombinerDelegate delegate;

  @override
  void initState() {
    super.initState();
    initDelegate();
  }

  void initDelegate() {
    delegate = PdfCombinerDelegate(onProgress: (updatedValue) {
      setState(() {
        _progress = updatedValue;
      });
    }, onError: (error) {
      _showSnackbarSafely(error.toString());
    }, onSuccess: (paths) {
      setState(() {
        _viewModel.outputFiles = paths;
      });
      _showSnackbarSafely('File/s generated successfully: $paths');
    });
  }

  bool isLoading() => _progress != 0.0 && _progress != 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Combiner Example'),
        actions: [
          IconButton(
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt),
            tooltip: "Restart app",
          ),
          IconButton(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add),
            tooltip: "Add new files",
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading()
            ? Center(
                child: CircularProgressIndicator(),
              )
            : DropTarget(
                onDragDone: (details) {
                  setState(() {
                    _viewModel.addFilesDragAndDrop(details.files);
                  });
                },
                child: (_viewModel.isEmpty())
                    ? Center(
                        child: Image.asset('assets/files/home.png'),
                      )
                    : Column(
                        spacing: 20,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_viewModel.outputFiles.isNotEmpty) ...[
                            // HERE IS THE OUTPUT SECTION
                            const SizedBox(),
                            const Text(
                              'OUTPUT FILES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              flex: calculateFlexOutputFiles(),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _viewModel.outputFiles.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      leading: FileTypeIcon(
                                          filePath:
                                              _viewModel.outputFiles[index]),
                                      title: Text(
                                        p.basename(
                                            _viewModel.outputFiles[index]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _openOutputFile(index),
                                      subtitle: FutureBuilder(
                                          future: FileMagicNumber
                                              .getBytesFromPathOrBlob(_viewModel
                                                  .outputFiles[index]),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text(
                                                  "Loading size...");
                                            } else if (snapshot.hasError) {
                                              return const Icon(Icons.error);
                                            } else {
                                              return Text(
                                                  snapshot.data?.size() ??
                                                      "Unknown Size");
                                            }
                                          }),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () =>
                                            _copyOutputToClipboard(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                          ],
                          // HERE IS THE INPUT SECTION
                          const Text(
                            'INPUT FILES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            flex: calculateFlexInputFiles(),
                            child: ReorderableListView.builder(
                              itemCount: _viewModel.selectedFiles.length,
                              onReorder: _onReorderFiles,
                              itemBuilder: (context, index) {
                                return Dismissible(
                                  key:
                                      ValueKey(_viewModel.selectedFiles[index]),
                                  direction: DismissDirection.horizontal,
                                  onDismissed: (direction) {
                                    final path = p.basename(
                                        _viewModel.selectedFiles[index].path);
                                    setState(() {
                                      _viewModel.removeFileAt(index);
                                    });
                                    _showSnackbarSafely('File $path removed.');
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      leading: FileTypeIcon(
                                          filePath:
                                              _viewModel.selectedFiles[index].path),
                                      title: Text(
                                        p.basename(
                                            _viewModel.selectedFiles[index].path),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () async =>
                                          await _openInputFile(index),
                                      subtitle: FutureBuilder(
                                          future: FileMagicNumber
                                              .getBytesFromPathOrBlob(_viewModel
                                                  .selectedFiles[index].path),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text(
                                                  "Loading size...");
                                            } else if (snapshot.hasError) {
                                              return const Icon(Icons.error);
                                            } else {
                                              return Text(
                                                  snapshot.data?.size() ??
                                                      "Unknown Size");
                                            }
                                          }),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Buttons Section
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                ElevatedButton(
                                  onPressed: _viewModel.selectedFiles.isNotEmpty
                                      ? _createPdfFromMixFromUint8List
                                      : null,
                                  child: const Text('Create PDF'),
                                ),
                                ElevatedButton(
                                  onPressed: _viewModel.selectedFiles.isNotEmpty
                                      ? _combinePdfsFromUint8List
                                      : null,
                                  child: const Text('Combine PDFs'),
                                ),
                                ElevatedButton(
                                  onPressed: _viewModel.selectedFiles.isNotEmpty
                                      ? _createPdfFromImagesFromUint8List
                                      : null,
                                  child: const Text('PDF from images'),
                                ),
                                ElevatedButton(
                                  onPressed: _viewModel.selectedFiles.isNotEmpty
                                      ? _createImagesFromPDFFromFile
                                      : null,
                                  child: const Text('Images from PDF'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
      ),
    );
  }

  // Calculate the flex value based on the number of items
  int calculateFlexInputFiles() => _viewModel.outputFiles.isEmpty ||
          _viewModel.selectedFiles.length <= _viewModel.outputFiles.length
      ? 1
      : 2;

  // Calculate the flex value based on the number of items
  int calculateFlexOutputFiles() =>
      _viewModel.outputFiles.length <= _viewModel.selectedFiles.length ? 1 : 2;

  // Function to pick PDF files from the device
  Future<void> _pickFiles() async {
    await _viewModel.pickFiles();
    setState(() {});
  }

  // Function to pick PDF files from the device
  void _restart() {
    _viewModel.restart();
    setState(() {
      _progress = 0.0;
    });
    _showSnackbarSafely('App restarted!');
  }
  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfsFromFile() async {
    await _viewModel.combinePdfsFromFile(delegate);
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfsFromString() async {
    await _viewModel.combinePdfsFromString(delegate);
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfsFromUint8List() async {
    await _viewModel.combinePdfsFromUint8List(delegate);
  }


  Future<void> _createPdfFromMixFromFile() async {
    await _viewModel.createPDFFromDocumentsFromFile(delegate);
  }

  Future<void> _createPdfFromMixFromString() async {
    await _viewModel.createPDFFromDocumentsFromString(delegate);
  }

  Future<void> _createPdfFromMixFromUint8List() async {
    await _viewModel.createPDFFromDocumentsFromUint8List(delegate);
  }

  Future<void> _createPdfFromImagesFromFile() async {
    await _viewModel.createPDFFromImagesFromFile(delegate);
  }

  Future<void> _createPdfFromImagesFromString() async {
    await _viewModel.createPDFFromImagesFromString(delegate);
  }

  Future<void> _createPdfFromImagesFromUint8List() async {
    await _viewModel.createPDFFromImagesFromUint8List(delegate);
  }

  Future<void> _createImagesFromPDFFromFile() async {
    await _viewModel.createImagesFromPDFFromFile(delegate);
  }

  Future<void> _createImagesFromPDFFromString() async {
    await _viewModel.createImagesFromPDFFromString(delegate);
  }

  Future<void> _copyOutputToClipboard(int index) async {
    await _viewModel.copyOutputToClipboard(index);
    _showSnackbarSafely('Output path copied to clipboard');
  }

  Future<void> _openOutputFile(int index) async {
    if (index < _viewModel.outputFiles.length) {
      final result = await OpenFile.open(_viewModel.outputFiles[index]);
      if (result.type != ResultType.done) {
        _showSnackbarSafely('Failed to open file. Error: ${result.message}');
      }
    }
  }

  Future<void> _openInputFile(int index) async {
    if (index < _viewModel.selectedFiles.length) {
      final result = await OpenFile.open(_viewModel.selectedFiles[index].path);
      if (result.type != ResultType.done) {
        _showSnackbarSafely('Failed to open file. Error: ${result.message}');
      }
    }
  }

  void _onReorderFiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final file = _viewModel.selectedFiles.removeAt(oldIndex);
      _viewModel.selectedFiles.insert(newIndex, file);
    });
  }

  void _showSnackbarSafely(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
