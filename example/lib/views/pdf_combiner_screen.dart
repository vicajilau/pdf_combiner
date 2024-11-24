import 'package:flutter/material.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      p.basename(_viewModel
                          .outputFile), // Show only the name of the file
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyOutputToClipboard,
                    ),
                  ),
                  const Divider(),
                ],
              ),
            // Input Files Section
            Expanded(
              child: ListView.builder(
                itemCount: _viewModel.selectedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      p.basename(_viewModel.selectedFiles[
                          index]), // Show only file name
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copySelectedFilesToClipboard(index),
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

  // Helper function to show SnackBar safely, checking if the widget is still mounted
  void _showSnackbarSafely(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
