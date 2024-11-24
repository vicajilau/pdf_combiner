import 'package:flutter/material.dart';
import 'package:pdf_combiner_example/pdf_combiner_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PDF Combiner Example',
      home: PdfCombinerExample(),
    );
  }
}
