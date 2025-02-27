package com.victorcarreras.pdf_combiner.subclasses

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import org.vudroid.core.DecodeServiceBase
import org.vudroid.core.codec.CodecPage
import org.vudroid.pdfdroid.codec.PdfContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException


class ImageFromPdfConfig(val rescale:ImageScale = ImageScale(maxWidth = 480, maxHeight = 640), val compression:ImageQuality= ImageQuality.custom(35), val createOneImage: Boolean = false)

class CreateImageFromPDF(getContext: Context, getResult: MethodChannel.Result) {

    private var context: Context = getContext
    private var result: MethodChannel.Result = getResult

    @OptIn(DelicateCoroutinesApi::class)
    fun create(
        inputPath: String, outputPath: String, config: ImageFromPdfConfig)
     {
        val pdfImagesPath: MutableList<String> = mutableListOf<String>()

        val pdfFromMultipleImage = GlobalScope.launch(Dispatchers.IO) {
            try {

                val decodeService = DecodeServiceBase(PdfContext())
                decodeService.setContentResolver(context.contentResolver)

                val file = File(inputPath)
                decodeService.open(Uri.fromFile(file))

                val pdfImages: MutableList<Bitmap> = mutableListOf<Bitmap>()

                val pageCount: Int = decodeService.pageCount
                for (i in 0 until pageCount) {
                    val page: CodecPage = decodeService.getPage(i)
                    val rectF = RectF(0.toFloat(), 0.toFloat(), 1.toFloat(), 1.toFloat())

                    val bitmap: Bitmap = page.renderBitmap(config.rescale.maxWidth, config.rescale.maxHeight, rectF)
                    pdfImages.add(bitmap)

                    if (!config.createOneImage) {

                        val splitPath = "$outputPath/image_$i.png"

                        print("pathfile: $splitPath")

                        pdfImagesPath.add(splitPath)
                        val outputStream = FileOutputStream(splitPath)
                        bitmap.compress(Bitmap.CompressFormat.PNG, config.compression.value, outputStream)
                        outputStream.close()
                    }
                }

                if (config.createOneImage) {
                    pdfImagesPath.add("$outputPath/image_pdf.png")
                    print("pathfile: $outputPath/image_pdf.png")
                    val bitmap = mergeThemAll(pdfImages, config.rescale.maxWidth, config.rescale.maxHeight)
                    val outputStream = FileOutputStream("$outputPath/image_pdf.png")
                    bitmap!!.compress(Bitmap.CompressFormat.PNG, config.compression.value, outputStream)
                    outputStream.close()
                }

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
        if (orderImagesList != null && orderImagesList.isNotEmpty()) {
            orderImagesList[0].width
            orderImagesList[0].height

            result = Bitmap.createBitmap(
                maxWidth, maxHeight * orderImagesList.size, Bitmap.Config.RGB_565
            )
            Log.d("myTag", "Create Bitmap")
            val canvas = Canvas(result)
            val paint = Paint()
            var chunkHeightCal: Int = 0
            for (i in orderImagesList.indices) {
                canvas.drawBitmap(
                    orderImagesList[i], (0).toFloat(), (chunkHeightCal).toFloat(), paint
                )
                chunkHeightCal = chunkHeightCal + maxHeight
            }
        } else {
            Log.e("MergeError", "Couldn't merge bitmaps")
        }
        return result
    }
}