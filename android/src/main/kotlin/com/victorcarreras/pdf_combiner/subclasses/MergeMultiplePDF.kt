package com.victorcarreras.pdf_combiner.subclasses

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.pdf.PdfDocument
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import org.apache.pdfbox.io.MemoryUsageSetting
import org.apache.pdfbox.multipdf.PDFMergerUtility


// Class for Merging Multiple PDF
class MergeMultiplePDF(getContext: Context, getResult: MethodChannel.Result) {

    private var context: Context = getContext
    private var result: MethodChannel.Result = getResult
    var status = ""


    fun mergePdfs(inputPaths: List<String>, outputPath: String) = GlobalScope.launch(Dispatchers.IO) {
        try {

            val outputDocument = PdfDocument()

            fun addPdfToDocument(pdfFile: File) {
                val fileDescriptor = ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(fileDescriptor)

                for (pageIndex in 0 until renderer.pageCount) {
                    val page = renderer.openPage(pageIndex)
                    val newPage = outputDocument.startPage(PdfDocument.PageInfo.Builder(page.width, page.height, pageIndex).create())

                    val canvas = newPage.canvas
                    val bitmap = Bitmap.createBitmap(page.width, page.height, Bitmap.Config.ARGB_8888)

                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                    canvas.drawBitmap(bitmap, 0f, 0f, null)

                    outputDocument.finishPage(newPage)
                    page.close()
                }

                renderer.close()
                fileDescriptor.close()
            }

            for (inputPath in inputPaths) {
                val pdfFile = File(inputPath)
                addPdfToDocument(pdfFile)
            }

            FileOutputStream(outputPath).use { outputStream ->
                outputDocument.writeTo(outputStream)
            }

            status = "success"
            outputDocument.close()
        } catch (e: IOException) {
            status = "error"
        }
    }
    // Method Merge multiple PDF file into one File
    // [paths] List of paths
    // [outputDirPath] Output directory path with file name added with it Ex . usr/android/download/ABC.pdf
    @OptIn(DelicateCoroutinesApi::class)
    fun merge(inputPaths: List<String>, outputPath: String) {
        val singlePDFFromMultiplePDF = mergePdfs(inputPaths,outputPath)

        // Method invoke after merging complete
        singlePDFFromMultiplePDF.invokeOnCompletion {
            if (status == "success") {
                status = outputPath
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