package com.victorcarreras.pdf_combiner

import androidx.annotation.NonNull
import android.content.Context
import com.ril.pdf_merger.CreateImageFromPDF
import com.ril.pdf_merger.CreatePDFFromMultipleImage
import com.ril.pdf_merger.MergeMultiplePDF

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** PdfCombinerPlugin */
class PdfCombinerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pdf_combiner")
    channel.setMethodCallHandler(this)
    this.context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "mergeMultiplePDF") {
      MergeMultiplePDF(context, result).merge(call.argument("paths"), call.argument("outputDirPath"))
    } else if (call.method == "createPDFFromMultipleImage") {
      CreatePDFFromMultipleImage(context, result).create(call.argument("paths"), call.argument("outputDirPath"), call.argument("needImageCompressor")
        , call.argument("maxWidth"), call.argument("maxHeight"))
    } else if (call.method == "createImageFromPDF") {
      CreateImageFromPDF(context, result).create(call.argument("path"), call.argument("outputDirPath")
        , call.argument("maxWidth"), call.argument("maxHeight"), call.argument("createOneImage"))
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
