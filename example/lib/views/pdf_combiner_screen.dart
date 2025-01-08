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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Output File Section
            if (_viewModel.outputFile.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Output File:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      p.basename(_viewModel.outputFile),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyOutputToClipboard,
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: _openOutputFile,
                        ),
                      ],
                    ),
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
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      setState(() {
                        _viewModel.removeFileAt(index);
                      });
                      _showSnackbarSafely(
                          'File ${p.basename(_viewModel.selectedFiles[index])} removed.');
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
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copySelectedFilesToClipboard(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Buttons Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickFiles,
                  child: const Text('Select PDF Files'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      _viewModel.selectedFiles.isNotEmpty ? _combinePdfs : null,
                  child: const Text('Combine PDFs'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Function to pick PDF files from the device
  Future<void> _pickFiles() async {
    await _viewModel.pickFiles(); // Call the ViewModel to pick files
    setState(() {}); // Refresh the UI after files are selected
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfs() async {
    try {
      await _viewModel.combinePdfs(); // Call the ViewModel to combine PDFs
      setState(() {}); // Refresh the UI after PDFs are combined
      _showSnackbarSafely(
          'PDFs combined successfully: ${_viewModel.outputFile}');
    } catch (e) {
      _showSnackbarSafely('Error: ${e.toString()}');
    }
  }

  // Function to copy the selected files' paths to the clipboard
  Future<void> _copySelectedFilesToClipboard(int index) async {
    await _viewModel.copySelectedFilesToClipboard(index);
    _showSnackbarSafely('Selected file copied to clipboard');
  }

  // Function to copy the output file path to the clipboard
  Future<void> _copyOutputToClipboard() async {
    await _viewModel.copyOutputToClipboard();
    _showSnackbarSafely('Output path copied to clipboard');
  }

  // Function to open the output file
  Future<void> _openOutputFile() async {
    if (_viewModel.outputFile.isNotEmpty) {
      final result = await OpenFile.open(_viewModel.outputFile);
      if (result.type != ResultType.done) {
        _showSnackbarSafely('Failed to open file. Error: ${result.message}');
      }
    }
  }

  // Handle reordering of files
  void _onReorderFiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final file = _viewModel.selectedFiles.removeAt(oldIndex);
      _viewModel.selectedFiles.insert(newIndex, file);
    });
  }

  // Helper function to show SnackBar safely, checking if the widget is still mounted
  void _showSnackbarSafely(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
