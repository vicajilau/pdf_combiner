package com.victorcarreras.pdf_combiner.subclasses

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.io.IOException


class ImageFromPdfConfig(
    val rescale: ImageScale,
    val compression: CompressionLevel,
    val createOneImage: Boolean
)

class CreateImageFromPDF(getContext: Context, getResult: MethodChannel.Result) {

    private var context: Context = getContext
    private var result: MethodChannel.Result = getResult

    @OptIn(DelicateCoroutinesApi::class)
    fun create(
        inputPath: String, outputPath: String, config: ImageFromPdfConfig
    ) {
        val pdfImagesPath: MutableList<String> = mutableListOf()

        val pdfFromMultipleImage = GlobalScope.launch(Dispatchers.IO) {
            try {
                val fileDescriptor = ParcelFileDescriptor.open(File(inputPath), ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(fileDescriptor)
                val pdfImages: MutableList<Bitmap> = mutableListOf()

                for (pageIndex in 0 until renderer.pageCount) {
                    val page = renderer.openPage(pageIndex)
                    val bitmap = Bitmap.createBitmap(page.width, page.height, Bitmap.Config.ARGB_8888)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    val imageName = "image_${pageIndex + 1}.png"
                    pdfImagesPath.add("$outputPath/$imageName")
                    val outputFile = File(outputPath, "$imageName")
                    FileOutputStream(outputFile).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, config.compression.value, out)
                        pdfImages.add(bitmap)
                    }
                    page.close()
                }

                if (config.createOneImage) {
                    val filepath = "$outputPath/image.png"
                    pdfImagesPath.clear()
                    pdfImagesPath.add(filepath)
                    Log.d("pdf_combiner", "pathfile: $filepath")
                    val bitmap = mergeThemAll(pdfImages, config.rescale.maxWidth, config.rescale.maxHeight)
                    FileOutputStream(filepath).use { out ->
                        bitmap?.compress(Bitmap.CompressFormat.PNG, config.compression.value, out)
                        bitmap?.let { pdfImages.add(it) }
                    }
                    val outputStream = FileOutputStream("$filepath")
                    bitmap?.compress(
                        Bitmap.CompressFormat.PNG,
                        config.compression.value,
                        outputStream
                    )
                    outputStream.close()
                }
                renderer.close()
                fileDescriptor.close()
            } catch (e: IOException) {
                e.printStackTrace()
            }
        }

        pdfFromMultipleImage.invokeOnCompletion {
            GlobalScope.launch(Dispatchers.Main) {
                result.success(pdfImagesPath)
            }
        }
    }

    private fun mergeThemAll(
        orderImagesList: List<Bitmap>?, maxWidth: Int, maxHeight: Int
    ): Bitmap? {
        var result: Bitmap? = null
        if (!orderImagesList.isNullOrEmpty()) {
            orderImagesList[0].width
            orderImagesList[0].height

            result = Bitmap.createBitmap(
                maxWidth, maxHeight * orderImagesList.size, Bitmap.Config.RGB_565
            )
            Log.d("pdf_combiner", "Create Bitmap")
            val canvas = Canvas(result)
            val paint = Paint()
            var chunkHeightCal = 0
            for (i in orderImagesList.indices) {
                canvas.drawBitmap(
                    orderImagesList[i], 0F, chunkHeightCal.toFloat(), paint
                )
                chunkHeightCal += maxHeight
            }
        } else {
            this.result.error("400", "MergeError", "Couldn't merge bitmaps")
        }
        return result
    }
}