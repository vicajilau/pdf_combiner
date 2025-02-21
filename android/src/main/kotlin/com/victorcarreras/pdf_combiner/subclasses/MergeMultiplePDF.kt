package com.victorcarreras.pdf_combiner.subclasses

import android.content.Context
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.multipdf.PDFMergerUtility
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream


// Class for Merging Multiple PDF
class MergeMultiplePDF(getContext: Context, getResult: MethodChannel.Result) {

    private var context: Context = getContext
    private var result: MethodChannel.Result = getResult

    // Method Merge multiple PDF file into one File
    // [paths] List of paths
    // [outputDirPath] Output directory path with file name added with it Ex . usr/android/download/ABC.pdf
    @OptIn(DelicateCoroutinesApi::class)
    fun merge(paths: List<String>, outputDirPath: String) {
        var status = ""

        PDFBoxResourceLoader.init(context.applicationContext)

        //Perform Operation in background thread
        val singlePDFFromMultiplePDF = GlobalScope.launch(Dispatchers.IO) {

            val ut = PDFMergerUtility()

            ut.documentMergeMode = PDFMergerUtility.DocumentMergeMode.OPTIMIZE_RESOURCES_MODE

            for (item in paths) {
                ut.addSource(item)
            }

            val file = File(outputDirPath)
            val fileOutputStream = FileOutputStream(file)
            try {
                ut.destinationStream = fileOutputStream
                ut.mergeDocuments(MemoryUsageSetting.setupTempFileOnly())
//                ut.mergeDocuments(true)
                status = "success"
            } catch (_: Exception) {
                status = "error"
            } finally {
                fileOutputStream.close()
            }
        }

        // Method invoke after merging complete
        singlePDFFromMultiplePDF.invokeOnCompletion {
            if (status == "success") {
                status = outputDirPath
            } else if (status == "error") {
                status = "error"
            }

            // Update result on main thread
            GlobalScope.launch(Dispatchers.Main) {
                result.success(status)
            }
        }
    }
}