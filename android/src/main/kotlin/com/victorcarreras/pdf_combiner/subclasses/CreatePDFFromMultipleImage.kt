package com.victorcarreras.pdf_combiner.subclasses

import android.graphics.*
import android.graphics.pdf.PdfDocument
import androidx.exifinterface.media.ExifInterface
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
                for (item in inputPaths) {

                    val bitmap = compressImage(
                        item, config.rescale.maxWidth, config.rescale.maxHeight,
                        config.keepAspectRatio
                    )
                    if (bitmap != null) {
                        val scaledBitmap = scaleBitmap(bitmap, config.rescale.maxWidth)
                        val pageInfo =
                            PdfDocument.PageInfo.Builder(
                                scaledBitmap.width,
                                scaledBitmap.height,
                                i + 1
                            ).create()
                        val page = pdfDocument.startPage(pageInfo)
                        val canvas = page.canvas
                        val paint = Paint()
                        canvas.drawPaint(paint)
                        canvas.drawBitmap(scaledBitmap, 0f, 0f, paint)
                        pdfDocument.finishPage(page)
                        scaledBitmap.recycle()
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

    private fun compressImage(
        imagePath: String,
        maxWidthGet: Int,
        maxHeightGet: Int,
        keepAspectRatio: Boolean
    ): Bitmap? {

        val maxHeight = maxWidthGet.toFloat()
        val maxWidth = maxHeightGet.toFloat()

        var scaledBitmap: Bitmap?

        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true

        var bmp: Bitmap? = BitmapFactory.decodeFile(imagePath, options)

        var actualHeight = options.outHeight
        var actualWidth = options.outWidth

        var imgRatio = actualWidth.toFloat() / actualHeight.toFloat()
        val maxRatio = maxWidth / maxHeight

        if (keepAspectRatio && actualHeight > maxHeight) {
            if (imgRatio < maxRatio) {
                imgRatio = maxHeight / actualHeight
                actualWidth = (imgRatio * actualWidth).toInt()
                actualHeight = maxHeight.toInt()
            } else if (imgRatio > maxRatio) {
                imgRatio = maxWidth / actualWidth
                actualHeight = (imgRatio * actualHeight).toInt()
                actualWidth = maxWidth.toInt()
            } else {
                actualHeight = maxHeight.toInt()
                actualWidth = maxWidth.toInt()

            }
        }

        calculateInSampleSize(options, actualWidth, actualHeight).also { options.inSampleSize = it }
        false.also { options.inJustDecodeBounds = false }
        false.also { options.inDither = false }
        true.also { options.inPurgeable = true }
        true.also { options.inInputShareable = true }
        ByteArray(16 * 1024).also { options.inTempStorage = it }

        try {
            bmp = BitmapFactory.decodeFile(imagePath, options)
        } catch (exception: OutOfMemoryError) {
            exception.printStackTrace()
            return null
        }

        try {
            scaledBitmap = Bitmap.createBitmap(actualWidth, actualHeight, Bitmap.Config.RGB_565)
        } catch (exception: OutOfMemoryError) {
            exception.printStackTrace()
            return null
        }

        val ratioX = actualWidth / options.outWidth.toFloat()
        val ratioY = actualHeight / options.outHeight.toFloat()
        val middleX = actualWidth / 2.0f
        val middleY = actualHeight / 2.0f

        val scaleMatrix = Matrix()
        scaleMatrix.setScale(ratioX, ratioY, middleX, middleY)

        Canvas(scaledBitmap).also {
            it.setMatrix(scaleMatrix)
            it.drawBitmap(
                bmp,
                middleX - bmp!!.width / 2,
                middleY - bmp.height / 2,
                Paint(Paint.FILTER_BITMAP_FLAG)
            )
        }

        bmp.run {
            recycle()
        }

        val exif: ExifInterface
        try {
            exif = ExifInterface(imagePath)
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_UNDEFINED
            )
            val matrix = Matrix()
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            }
            Bitmap.createBitmap(
                scaledBitmap,
                0,
                0,
                scaledBitmap.width,
                scaledBitmap.height,
                matrix,
                true
            ).also { scaledBitmap = it }
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return scaledBitmap
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
