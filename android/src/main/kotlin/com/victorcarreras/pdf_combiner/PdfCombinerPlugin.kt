package com.victorcarreras.pdf_combiner

import android.content.Context
import com.victorcarreras.pdf_combiner.subclasses.CreatePDFFromMultipleImage
import com.victorcarreras.pdf_combiner.subclasses.MergeMultiplePDF
import com.victorcarreras.pdf_combiner.subclasses.CreateImageFromPDF
import com.victorcarreras.pdf_combiner.subclasses.CompressionLevel
import com.victorcarreras.pdf_combiner.subclasses.ImageFromPdfConfig
import com.victorcarreras.pdf_combiner.subclasses.ImageScale
import com.victorcarreras.pdf_combiner.subclasses.PdfFromMultipleImageConfig

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
    when (call.method) {
      "mergeMultiplePDF" -> {
        val paths = call.argument<List<String>>("paths")
        val outputDirPath = call.argument<String>("outputDirPath")
        if (paths != null && outputDirPath != null) {
          MergeMultiplePDF(context, result).merge(paths, outputDirPath)
        } else {
          result.error("INVALID_ARGUMENTS", "paths or outputDirPath cannot be null", null)
        }
      }

      "createPDFFromMultipleImage" -> {
        val paths = call.argument<List<String>>("paths")
        val outputDirPath = call.argument<String>("outputDirPath")
        val maxWidth = call.argument<Int>("width")
        val maxHeight = call.argument<Int>("height")
        val keepAspectRatio = call.argument<Boolean>("keepAspectRatio")
        if (paths != null && outputDirPath != null) {
          CreatePDFFromMultipleImage(result).create(
            paths,
            outputDirPath,
            PdfFromMultipleImageConfig(
              ImageScale(maxWidth!!, maxHeight!!),
              keepAspectRatio
            )
          )
        } else {
          result.error("INVALID_ARGUMENTS", "paths or outputDirPath cannot be null", null)
        }
      }

      "createImageFromPDF" -> {
        val path = call.argument<String>("path")
        val outputDirPath = call.argument<String>("outputDirPath")
        val compression = call.argument<Int>("compression")
        val maxWidth = call.argument<Int>("width")
        val maxHeight = call.argument<Int>("height")
        val createOneImage = call.argument<Boolean>("createOneImage")

        if (path != null && outputDirPath != null) {
          CreateImageFromPDF(context, result).create(
            path, outputDirPath, ImageFromPdfConfig(
              ImageScale(maxWidth!!, maxHeight!!),
              CompressionLevel.getCompressionLevel(compression!!), createOneImage!!
            )
          )
        } else {
          result.error("INVALID_ARGUMENTS", "path or outputDirPath cannot be null", null)
        }
      }

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
