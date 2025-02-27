import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../view_models/pdf_combiner_view_model.dart';

class PdfCombinerScreen extends StatefulWidget {
  const PdfCombinerScreen({super.key});

  @override
  State<PdfCombinerScreen> createState() => _PdfCombinerScreenState();
}

class _PdfCombinerScreenState extends State<PdfCombinerScreen> {
  final PdfCombinerViewModel _viewModel = PdfCombinerViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Combiner Example'),
        actions: [
          IconButton(
            onPressed: () => _restart(),
            icon: const Icon(Icons.restart_alt),
            tooltip: "Restart app",
          ),
          IconButton(
            onPressed: () => _pickFiles(),
            icon: const Icon(Icons.add),
            tooltip: "Add new files",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Output Files Section
            if (_viewModel.outputFiles.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Output Files:',
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
                        title: Text(
                          p.basename(_viewModel.outputFiles[index]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyOutputToClipboard(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () => _openOutputFile(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
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
                      final path = p.basename(_viewModel.selectedFiles[index]);
                      setState(() {
                        _viewModel.removeFileAt(index);
                      });
                      _showSnackbarSafely('File $path removed.');
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      title: Text(
                        p.basename(_viewModel.selectedFiles[index]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(_viewModel.selectedFiles[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _openInputFile(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Buttons Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
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
    setState(() {});
    _showSnackbarSafely('App restarted!');
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfs() async {
    try {
      await _viewModel.combinePdfs();
      setState(() {});
      _showSnackbarSafely(
          'PDFs combined successfully: ${_viewModel.outputFiles.first}');
    } catch (e) {
      _showSnackbarSafely(e.toString());
    }
  }

  Future<void> _createPdfFromImages() async {
    try {
      await _viewModel.createPDFFromImages();
      setState(() {});
      _showSnackbarSafely(
          'PDF created successfully: ${_viewModel.outputFiles.first}');
    } catch (e) {
      _showSnackbarSafely(e.toString());
    }
  }

  Future<void> _createImagesFromPDF() async {
    try {
      await _viewModel.createImagesFromPDF();
      setState(() {});
      _showSnackbarSafely(
          'Images created successfully: ${_viewModel.outputFiles}');
    } catch (e) {
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
