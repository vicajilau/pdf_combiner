import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
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
  bool isLoading = false;

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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : DropTarget(
                onDragDone: (details) {
                  setState(() {
                    _viewModel.addFilesDragAndDrop(details.files);
                  });
                },
                child: Column(
                  spacing: 20,
                  children: [
                    // Output Files Section
                    if (_viewModel.outputFiles.isNotEmpty)
                      Column(
                        children: [
                          const Text(
                            'OUTPUT FILES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: _viewModel.outputFiles.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: FileTypeIcon(
                                    filePath: _viewModel.outputFiles[index]),
                                title: Text(
                                  p.basename(_viewModel.outputFiles[index]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _openOutputFile(index),
                                subtitle: Text(_viewModel.outputFiles[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () =>
                                      _copyOutputToClipboard(index),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                        ],
                      ),
                    const Text(
                      'INPUT FILES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Input Files Section
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: _viewModel.selectedFiles.length,
                        onReorder: _onReorderFiles,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: ValueKey(_viewModel.selectedFiles[index]),
                            direction: DismissDirection.horizontal,
                            onDismissed: (direction) {
                              final path =
                                  p.basename(_viewModel.selectedFiles[index]);
                              setState(() {
                                _viewModel.removeFileAt(index);
                              });
                              _showSnackbarSafely('File $path removed.');
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: FileTypeIcon(
                                    filePath: _viewModel.selectedFiles[index]),
                                title: Text(
                                  p.basename(_viewModel.selectedFiles[index]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () async => await _openInputFile(index),
                                subtitle: FutureBuilder(
                                    future:
                                        FileMagicNumber.getBytesFromPathOrBlob(
                                            _viewModel.selectedFiles[index]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text("Loading size...");
                                      } else if (snapshot.hasError) {
                                        return const Icon(Icons.error);
                                      } else {
                                        return Text(snapshot.data?.size() ??
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
                                ? _createPdfFromMix
                                : null,
                            child: const Text('Create PDF'),
                          ),
                          ElevatedButton(
                            onPressed: _viewModel.selectedFiles.isNotEmpty
                                ? _combinePdfs
                                : null,
                            child: const Text('Combine PDFs'),
                          ),
                          ElevatedButton(
                            onPressed: _viewModel.selectedFiles.isNotEmpty
                                ? _createPdfFromImages
                                : null,
                            child: const Text('PDF from images'),
                          ),
                          ElevatedButton(
                            onPressed: _viewModel.selectedFiles.isNotEmpty
                                ? _createImagesFromPDF
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

  // Function to pick PDF files from the device
  Future<void> _pickFiles() async {
    await _viewModel.pickFiles();
    setState(() {});
  }

  // Function to pick PDF files from the device
  void _restart() {
    _viewModel.restart();
    setState(() {
      changeLoading(false);
    });
    _showSnackbarSafely('App restarted!');
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfs() async {
    try {
      changeLoading(true);
      await _viewModel.combinePdfs();
      changeLoading(false);
      _showSnackbarSafely(
          'PDFs combined successfully: ${_viewModel.outputFiles.first}');
    } catch (e) {
      changeLoading(false);
      _showSnackbarSafely(e.toString());
    }
  }

  void changeLoading(bool isLoading) => setState(() {
        this.isLoading = isLoading;
      });

  Future<void> _createPdfFromMix() async {
    try {
      changeLoading(true);
      await _viewModel.createPDFFromDocuments();
      changeLoading(false);
      _showSnackbarSafely(
          'PDF created successfully: ${_viewModel.outputFiles.first}');
    } catch (e) {
      changeLoading(false);
      _showSnackbarSafely(e.toString());
    }
  }

  Future<void> _createPdfFromImages() async {
    try {
      changeLoading(true);
      await _viewModel.createPDFFromImages();
      changeLoading(false);
      _showSnackbarSafely(
          'PDF created successfully: ${_viewModel.outputFiles.first}');
    } catch (e) {
      changeLoading(false);
      _showSnackbarSafely(e.toString());
    }
  }

  Future<void> _createImagesFromPDF() async {
    try {
      changeLoading(true);
      await _viewModel.createImagesFromPDF();
      changeLoading(false);
      _showSnackbarSafely(
          'Images created successfully: ${_viewModel.outputFiles}');
    } catch (e) {
      changeLoading(false);
      _showSnackbarSafely(e.toString());
    }
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
      final result = await OpenFile.open(_viewModel.selectedFiles[index]);
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
