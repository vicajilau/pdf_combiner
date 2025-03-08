package com.victorcarreras.pdf_combiner.subclasses

import android.graphics.*
import android.graphics.pdf.PdfDocument
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import kotlin.math.roundToInt

class ImageScale(
    val maxWidth: Int,
    val maxHeight: Int,
)

class CompressionLevel(val value: Int)
class PdfFromMultipleImageConfig(val rescale: ImageScale, val keepAspectRatio: Boolean)


class CreatePDFFromMultipleImage(getResult: MethodChannel.Result) {

    private var result: MethodChannel.Result = getResult

    @OptIn(DelicateCoroutinesApi::class)
    fun create(
        inputPaths: List<String>,
        outputPath: String,
        config: PdfFromMultipleImageConfig,
    ) {
        var status = ""

        val pdfFromMultipleImage = GlobalScope.launch(Dispatchers.IO) {
            try {
                val file = File(outputPath)
                val fileOutputStream = FileOutputStream(file)
                val pdfDocument = PdfDocument()
                val i = 0
                val width = config.rescale.maxWidth
                val height = config.rescale.maxHeight
                for (item in inputPaths) {
                    var bitmap: Bitmap? = null
                    if (width == 0 && height == 0) {
                        bitmap = BitmapFactory.decodeFile(item)
                    } else {
                        bitmap = rescaleImage(
                            item, width, height,
                            config.keepAspectRatio
                        )
                    }
                    if (bitmap != null) {
                        val pageInfo =
                            PdfDocument.PageInfo.Builder(
                                bitmap.width,
                                bitmap.height,
                                i + 1
                            ).create()
                        val page = pdfDocument.startPage(pageInfo)
                        val canvas = page.canvas
                        val paint = Paint()
                        canvas.drawPaint(paint)
                        canvas.drawBitmap(bitmap, 0f, 0f, paint)
                        pdfDocument.finishPage(page)
                        bitmap.recycle()
                        pdfDocument.writeTo(fileOutputStream)
                        status = "success"
                    } else {
                        status = "error"
                    }

                }
                pdfDocument.close()
            } catch (e: IOException) {
                e.printStackTrace()
                status = "error"
            }
        }

        pdfFromMultipleImage.invokeOnCompletion {
            if (status == "success")
                status = outputPath
            else if (status == "error")
                status = "error"

            GlobalScope.launch(Dispatchers.Main) {
                result.success(status)
            }
        }
    }

    // Scale image maintaining proportions
    private fun scaleBitmap(bitmap: Bitmap, targetWidth: Int): Bitmap {
        val scaleFactor = targetWidth.toFloat() / bitmap.width
        val targetHeight = (bitmap.height * scaleFactor).toInt()
        return Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
    }

    // Rescale image maintaining proportions
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

            Bitmap.createScaledBitmap(originalBitmap, targetWidth, targetHeight, true)
        } else {
            Bitmap.createScaledBitmap(originalBitmap, width, height, true)
        }
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val heightRatio = (height.toFloat() / reqHeight.toFloat()).roundToInt()
            val widthRatio = (width.toFloat() / reqWidth.toFloat()).roundToInt()
            inSampleSize = if (heightRatio < widthRatio) heightRatio else widthRatio
        }
        val totalPixels = (width * height).toFloat()
        val totalReqPixelsCap = (reqWidth * reqHeight * 2).toFloat()

        while (totalPixels / (inSampleSize * inSampleSize) > totalReqPixelsCap) {
            inSampleSize++
        }

        return inSampleSize
    }


}
