package com.ril.pdf_merger

import android.content.Context
import io.flutter.plugin.common.MethodChannel
import android.annotation.TargetApi
import android.graphics.*
import android.graphics.pdf.PdfDocument
import android.os.Build
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class CreatePDFFromMultipleImage(getContext : Context, getResult : MethodChannel.Result) {

    private var context: Context = getContext
    private var result: MethodChannel.Result = getResult


    @TargetApi(Build.VERSION_CODES.KITKAT)
    fun create(paths: List<String>?, outputDirPath: String?, needImageCompressor : Boolean?
                                           , maxWidth : Int?, maxHeight : Int?)  {
        var status = ""

        val pdfFromMultipleImage =  GlobalScope.launch(Dispatchers.IO) {
            try {
                val file = File(outputDirPath!!)
                val fileOutputStream = FileOutputStream(file)
                val pdfDocument = PdfDocument()
                val i=0;
                for (item in paths!!){
                    var bitmap : Bitmap?

                    if(needImageCompressor!!)
                        bitmap =  compressImage(context, item, maxWidth!!, maxHeight!!)
                    else
                        bitmap = BitmapFactory.decodeFile(item)


                    val pageInfo = PdfDocument.PageInfo.Builder(bitmap!!.width, bitmap.height, i + 1).create()
                    val page = pdfDocument.startPage(pageInfo)
                    val canvas = page.canvas
                    val paint = Paint()
                    canvas.drawPaint(paint)
                    canvas.drawBitmap(bitmap, 0f, 0f, paint)
                    pdfDocument.finishPage(page)
                    bitmap.recycle()
                }
                pdfDocument.writeTo(fileOutputStream)
                pdfDocument.close()
                status = "success"
            } catch (e: IOException) {
                e.printStackTrace()
                status = "error"

            }
        }

        pdfFromMultipleImage.invokeOnCompletion {
            if(status == "success")
                status = outputDirPath!!
            else if(status == "error")
                status = "error"

            GlobalScope.launch(Dispatchers.Main) {
                result.success(status)
            }
        }
    }

    private fun compressImage(context: Context, imagePath: String, maxWidthGet : Int, maxHeightGet : Int): Bitmap? {

        val maxHeight = maxWidthGet.toFloat()
        val maxWidth = maxHeightGet.toFloat()

        var scaledBitmap: Bitmap?

        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        @Suppress("VARIABLE_WITH_REDUNDANT_INITIALIZER")
        var bmp: Bitmap? = BitmapFactory.decodeFile(imagePath, options)

        var actualHeight = options.outHeight
        var actualWidth = options.outWidth

        var imgRatio = actualWidth.toFloat() / actualHeight.toFloat()
        val maxRatio = maxWidth / maxHeight

        if (actualHeight > maxHeight || actualWidth > maxWidth) {
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
        false.also { options.inJustDecodeBounds = it }
        false.also { options.inDither = it }
        true.also { options.inPurgeable = it }
        true.also { options.inInputShareable = it }
        ByteArray(16 * 1024).also { options.inTempStorage = it }

        try {
            bmp = BitmapFactory.decodeFile(imagePath, options)
            val baos = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, 10, baos)
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
            it.drawBitmap(bmp, middleX - bmp!!.width / 2, middleY - bmp.height / 2, Paint(Paint.FILTER_BITMAP_FLAG))
        }

        bmp.run {
            recycle()
        }

        val exif: ExifInterface
        try {
            exif = ExifInterface(imagePath)
            val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED)
            val matrix = Matrix()
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            }
            Bitmap.createBitmap(scaledBitmap!!,
                0,
                0,
                scaledBitmap.width,
                scaledBitmap.height,
                matrix,
                true).also { scaledBitmap = it }
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return scaledBitmap
    }


    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val heightRatio = Math.round(height.toFloat() / reqHeight.toFloat())
            val widthRatio = Math.round(width.toFloat() / reqWidth.toFloat())
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
