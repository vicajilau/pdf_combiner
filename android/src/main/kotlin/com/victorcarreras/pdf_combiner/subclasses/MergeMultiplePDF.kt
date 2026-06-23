package com.victorcarreras.pdf_combiner.subclasses

import android.content.Context
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.multipdf.PDFMergerUtility
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream


// Class for Merging Multiple PDF
class MergeMultiplePDF(private val result: MethodChannel.Result) {

    private val scope = CoroutineScope(Dispatchers.Main)

    // Method Merge multiple PDF file into one File
    // [paths] List of paths
    // [outputDirPath] Output directory path with file name added with it Ex . usr/android/download/ABC.pdf
    fun merge(context: Context, inputPaths: List<String>, outputPath: String) {
        scope.launch {
            try {
                val finalPath = withContext(Dispatchers.IO) {
                    PDFBoxResourceLoader.init(context.applicationContext)
                    val ut = PDFMergerUtility()
                    ut.documentMergeMode = PDFMergerUtility.DocumentMergeMode.OPTIMIZE_RESOURCES_MODE

                    for (item in inputPaths) {
                        ut.addSource(item)
                    }

                    val file = File(outputPath)
                    FileOutputStream(file).use { fileOutputStream ->
                        ut.destinationStream = fileOutputStream
                        ut.mergeDocuments(MemoryUsageSetting.setupTempFileOnly())
                    }
                    outputPath
                }
                result.success(finalPath)
            } catch (e: Exception) {
                result.error("MERGE_ERROR", e.message, null)
            }
        }
    }
}
