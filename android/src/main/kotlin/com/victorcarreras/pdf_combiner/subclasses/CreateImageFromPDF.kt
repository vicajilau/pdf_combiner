package com.victorcarreras.pdf_combiner.subclasses

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import androidx.core.graphics.createBitmap


class ImageFromPdfConfig(
    val rescale: ImageScale,
    val compression: CompressionLevel,
    val createOneImage: Boolean
)

class CreateImageFromPDF(private val result: MethodChannel.Result) {

    private val scope = CoroutineScope(Dispatchers.Default)

    fun create(
        inputPath: String, outputPath: String, config: ImageFromPdfConfig
    ) {
        scope.launch {
            try {
                withContext(Dispatchers.IO) {
                    val pdfImagesPath: MutableList<String> = mutableListOf()
                    val fileDescriptor = ParcelFileDescriptor.open(File(inputPath), ParcelFileDescriptor.MODE_READ_ONLY)
                    val renderer = PdfRenderer(fileDescriptor)
                    val pdfImages: MutableList<Bitmap> = mutableListOf()

                    try {
                        for (pageIndex in 0 until renderer.pageCount) {
                            val page = renderer.openPage(pageIndex)
                            val bitmap = createBitmap(page.width, page.height)
                            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            val imageName = "image_${pageIndex + 1}.png"
                            val outputFile = File(outputPath, imageName)
                            
                            FileOutputStream(outputFile).use { out ->
                                bitmap.compress(Bitmap.CompressFormat.PNG, config.compression.value, out)
                                pdfImages.add(bitmap)
                                pdfImagesPath.add(outputFile.absolutePath)
                            }
                            page.close()
                        }

                        if (config.createOneImage) {
                            val filepath = File(outputPath, "image.png").absolutePath
                            val mergedBitmap = mergeThemAll(pdfImages, config.rescale.maxWidth, config.rescale.maxHeight)
                            if (mergedBitmap != null) {
                                FileOutputStream(filepath).use { out ->
                                    mergedBitmap.compress(Bitmap.CompressFormat.PNG, config.compression.value, out)
                                }
                                pdfImagesPath.clear()
                                pdfImagesPath.add(filepath)
                                mergedBitmap.recycle()
                            }
                        }
                    } finally {
                        renderer.close()
                        fileDescriptor.close()
                        for (bitmap in pdfImages) {
                            bitmap.recycle()
                        }
                    }
                    result.success(pdfImagesPath)
                }
            } catch (e: Exception) {
                result.error("IMAGE_CREATION_ERROR", e.message, null)
            }
        }
    }

    private fun mergeThemAll(
        orderImagesList: List<Bitmap>, maxWidth: Int, maxHeight: Int
    ): Bitmap? {
        if (orderImagesList.isEmpty()) return null
        
        val result = createBitmap(maxWidth, maxHeight * orderImagesList.size, Bitmap.Config.RGB_565)
        val canvas = Canvas(result)
        val paint = Paint()
        var chunkHeightCal = 0
        for (i in orderImagesList.indices) {
            canvas.drawBitmap(
                orderImagesList[i], 0F, chunkHeightCal.toFloat(), paint
            )
            chunkHeightCal += maxHeight
        }
        return result
    }
}
