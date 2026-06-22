import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_combiner/communication/pdf_combiner_method_channel.dart';
import 'package:pdf_combiner/models/merge_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelPdfCombiner - argument validation', () {
    late MethodChannelPdfCombiner platform;

    setUp(() {
      platform = MethodChannelPdfCombiner();
    });

    test('mergeMultiplePDFs throws ArgumentError when any input lacks path', () async {
      final inputs = [MergeInputPath('a.pdf'), MergeInputBytes(Uint8List.fromList([1, 2]))];
      await expectLater(() => platform.mergeMultiplePDFs(inputs: inputs, outputPath: '/out'), throwsA(isA<ArgumentError>()));
    });

    test('createPDFFromMultipleImages throws ArgumentError when any input lacks path', () async {
      final inputs = [MergeInputPath('a.jpg'), MergeInputBytes(Uint8List.fromList([1, 2]))];
      await expectLater(() => platform.createPDFFromMultipleImages(inputs: inputs, outputPath: '/out'), throwsA(isA<ArgumentError>()));
    });

    test('createImageFromPDF throws ArgumentError when input lacks path', () async {
      final input = MergeInputBytes(Uint8List.fromList([1, 2]));
      await expectLater(() => platform.createImageFromPDF(input: input, outputPath: '/out'), throwsA(isA<ArgumentError>()));
    });
  });
}

