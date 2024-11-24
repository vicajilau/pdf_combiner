import 'package:flutter/material.dart';

import '../view_models/pdf_combiner_view_model.dart';
import 'common/copiable_text.dart';

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFiles, // Button to pick files
              child: const Text('Select PDF Files'),
            ),
            ElevatedButton(
              onPressed: _viewModel.selectedFiles.isNotEmpty
                  ? _combinePdfs
                  : null, // Button to combine PDFs (enabled only if files are selected)
              child: const Text('Combine PDFs'),
            ),
            const SizedBox(height: 20),
            CopyableText(
              text: 'Selected Files:\n${_viewModel.selectedFiles.join('\n')}',
              onCopy: _copySelectedFilesToClipboard,
            ),
            const SizedBox(height: 20),
            CopyableText(
              text: 'Output File:\n${_viewModel.outputFile}',
              onCopy: _copyOutputToClipboard,
              textStyle: const TextStyle(fontSize: 14, color: Colors.green),
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
  Future<void> _copySelectedFilesToClipboard() async {
    await _viewModel.copySelectedFilesToClipboard();
    _showSnackbarSafely('Selected files copied to clipboard');
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
