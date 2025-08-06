import 'package:flutter/material.dart';
import 'package:pdf_combiner_example/utils/theme.dart';
import 'package:pdf_combiner_example/views/pdf_combiner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Combiner Example',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const PdfCombinerScreen(),
    );
  }
}
