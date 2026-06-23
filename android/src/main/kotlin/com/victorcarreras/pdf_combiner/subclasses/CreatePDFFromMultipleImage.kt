package com.victorcarreras.pdf_combiner.subclasses

import android.graphics.*
import android.graphics.pdf.PdfDocument
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import androidx.core.graphics.scale

class ImageScale(
    val maxWidth: Int,
    val maxHeight: Int,
)

class CompressionLevel(val value: Int)
class PdfFromMultipleImageConfig(val rescale: ImageScale, val keepAspectRatio: Boolean)


class CreatePDFFromMultipleImage(private val result: MethodChannel.Result) {

    private val scope = CoroutineScope(Dispatchers.Default)

    fun create(
        inputPaths: List<String>,
        outputPath: String,
        config: PdfFromMultipleImageConfig,
    ) {
        scope.launch {
            try {
                val finalPath = withContext(Dispatchers.IO) {
                    val file = File(outputPath)
                    val pdfDocument = PdfDocument()
                    val width = config.rescale.maxWidth
                    val height = config.rescale.maxHeight
                    
                    try {
                        FileOutputStream(file).use { fileOutputStream ->
                            for ((index, item) in inputPaths.withIndex()) {
                                val bitmap: Bitmap? = if (width == 0 && height == 0) {
                                    BitmapFactory.decodeFile(item)
                                } else {
                                    rescaleImage(item, width, height, config.keepAspectRatio)
                                }

                                if (bitmap != null) {
                                    val pageInfo = PdfDocument.PageInfo.Builder(
                                        bitmap.width,
                                        bitmap.height,
                                        index + 1
                                    ).create()
                                    val page = pdfDocument.startPage(pageInfo)
                                    val canvas = page.canvas
                                    canvas.drawBitmap(bitmap, 0f, 0f, null)
                                    pdfDocument.finishPage(page)
                                    bitmap.recycle()
                                }
                            }
                            pdfDocument.writeTo(fileOutputStream)
                        }
                    } finally {
                        pdfDocument.close()
                    }
                    outputPath
                }
                result.success(finalPath)
            } catch (e: Exception) {
                result.error("PDF_CREATION_ERROR", e.message, null)
            }
        }
    }

    private fun rescaleImage(
        imagePath: String,
        width: Int,
        height: Int,
        keepAspectRatio: Boolean
    ): Bitmap? {
        val originalBitmap = BitmapFactory.decodeFile(imagePath) ?: return null

        return if (keepAspectRatio) {
            val aspectRatio = originalBitmap.width.toFloat() / originalBitmap.height.toFloat()
            val targetWidth: Int
            val targetHeight: Int

            if (originalBitmap.width > originalBitmap.height) {
                targetWidth = width
                targetHeight = (width / aspectRatio).toInt()
            } else {
                targetHeight = height
                targetWidth = (height * aspectRatio).toInt()
            }

            originalBitmap.scale(targetWidth, targetHeight)
        } else {
            originalBitmap.scale(width, height)
        }
    }
}
