import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner_example/utils/uint8list_extension.dart';
import 'package:pdf_combiner_example/views/widgets/file_type_dialog.dart';
import 'package:pdf_combiner_example/views/widgets/file_type_icon.dart';

import '../view_models/pdf_combiner_view_model.dart';

extension on MergeInput {
  String fileName(int? index) {
    switch (type) {
      case MergeInputType.path:
        return p.basename(path ?? '');
      case MergeInputType.bytes:
        return 'File in bytes $index';
    }
  }
}

class PdfCombinerScreen extends StatefulWidget {
  const PdfCombinerScreen({super.key});

  @override
  State<PdfCombinerScreen> createState() => _PdfCombinerScreenState();
}

class _PdfCombinerScreenState extends State<PdfCombinerScreen> {
  final PdfCombinerViewModel _viewModel = PdfCombinerViewModel();
  bool _isLoading = false;

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
        child: Stack(
          children: [
            DropTarget(
              onDragDone: (details) async {
                final fileType =
                    await showFileTypeDialog(context); // Show dialog
                if (fileType == null) return;
                await _viewModel.addFilesDragAndDrop(fileType, details.files);
                setState(() {});
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
                                        input: MergeInput.path(
                                            _viewModel.outputFiles[index])),
                                    title: Text(
                                      p.basename(_viewModel.outputFiles[index]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _openOutputFile(index),
                                    subtitle: FutureBuilder(
                                        future: FileMagicNumber
                                            .getBytesFromPathOrBlob(
                                                _viewModel.outputFiles[index]),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text(
                                                "Loading size...");
                                          } else if (snapshot.hasError) {
                                            return const Icon(Icons.error);
                                          } else {
                                            return Text(snapshot.data?.size() ??
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
                                key: ValueKey(_viewModel.selectedFiles[index]),
                                direction: DismissDirection.horizontal,
                                onDismissed: (direction) {
                                  final file = _viewModel.selectedFiles[index];
                                  setState(() {
                                    _viewModel.removeFileAt(index);
                                  });
                                  _showSnackbarSafely(
                                      'File ${file.fileName(index + 1)} removed.');
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
                                        input: _viewModel.selectedFiles[index]),
                                    title: Builder(builder: (context) {
                                      final file =
                                          _viewModel.selectedFiles[index];
                                      return Text(
                                        file.fileName(index + 1),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }),
                                    onTap: () async {
                                      await _openInputFile(index);
                                    },
                                    subtitle: FutureBuilder(
                                        future: switch (_viewModel
                                            .selectedFiles[index].type) {
                                          MergeInputType.bytes => Future.value(
                                              _viewModel
                                                  .selectedFiles[index].bytes),
                                          MergeInputType.path => FileMagicNumber
                                              .getBytesFromPathOrBlob(_viewModel
                                                  .selectedFiles[index]
                                                  .toString()),
                                        },
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text(
                                                "Loading size...");
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
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
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
    final fileType = await showFileTypeDialog(context);
    if (fileType == null) return;
    await _viewModel.pickFiles(fileType);
    setState(() {});
  }

  // Function to pick PDF files from the device
  void _restart() {
    _viewModel.restart();
    setState(() {});
    _showSnackbarSafely('App restarted!');
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await action();
      _showSnackbarSafely(
        'File/s generated successfully: ${_viewModel.outputFiles}',
      );
    } on PdfCombinerException catch (e) {
      _showSnackbarSafely(e.message);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfs() async {
    await _runSafely(() async {
      await _viewModel.combinePdfs();
    });
  }

  Future<void> _createPdfFromMix() async {
    await _runSafely(() async {
      await _viewModel.createPDFFromDocuments();
    });
  }

  Future<void> _createPdfFromImages() async {
    await _runSafely(() async {
      await _viewModel.createPDFFromImages();
    });
  }

  Future<void> _createImagesFromPDF() async {
    await _runSafely(() async {
      await _viewModel.createImagesFromPDF();
    });
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
      switch (_viewModel.selectedFiles[index].type) {
        case MergeInputType.path:
          final result =
              await OpenFile.open(_viewModel.selectedFiles[index].toString());
          if (result.type != ResultType.done) {
            _showSnackbarSafely(
                'Failed to open file. Error: ${result.message}');
          }
          return;
        case MergeInputType.bytes:
          return;
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
