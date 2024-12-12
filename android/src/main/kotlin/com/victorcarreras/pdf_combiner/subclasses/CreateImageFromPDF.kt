package com.ril.pdf_merger

import android.annotation.TargetApi
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import org.vudroid.core.DecodeServiceBase
import org.vudroid.core.codec.CodecPage
import org.vudroid.pdfdroid.codec.PdfContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class CreateImageFromPDF(getContext : Context, getResult : MethodChannel.Result) {

    private var context: Context = getContext
    private var result: MethodChannel.Result = getResult


    @TargetApi(Build.VERSION_CODES.KITKAT)
    fun create(path: String?, outputDirPath: String?, maxWidth : Int?, maxHeight : Int?
                                   , createOneImage : Boolean?)  {
        var status = ""
        val pdfImagesPath :  MutableList<String> = mutableListOf<String>()


        val pdfFromMultipleImage =  GlobalScope.launch(Dispatchers.IO) {
            try {

                val decodeService = DecodeServiceBase(PdfContext())
                decodeService.setContentResolver(context.contentResolver)

                val file = File(path)
                decodeService.open(Uri.fromFile(file))

                val pdfImages :  MutableList<Bitmap> = mutableListOf<Bitmap>()

                val pageCount: Int = decodeService.pageCount
                for (i in 0 until pageCount) {
                    val page: CodecPage = decodeService.getPage(i)
                    val rectF = RectF(0.toFloat(), 0.toFloat(), 1.toFloat(), 1.toFloat())

                    val bitmap: Bitmap = page.renderBitmap(maxWidth!!, maxHeight!!, rectF)
                    pdfImages.add(bitmap)

                    if(!createOneImage!!){

                        val splitPath = outputDirPath!!.split(".")[0]
                        val splitPathExt = outputDirPath.split(".")[1];

                        print(splitPath)
                        print(splitPathExt)

                        val newPath = """$splitPath$i.$splitPathExt"""
                        pdfImagesPath.add(newPath)
                        val outputStream = FileOutputStream(newPath)
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                        outputStream.close()
                    }
                }


                if(createOneImage!!){
                    pdfImagesPath.add(outputDirPath!!)
                    val bitmap = mergeThemAll(pdfImages, maxWidth!!, maxHeight!!)
                    val outputStream = FileOutputStream(outputDirPath)
                    bitmap!!.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
                    outputStream.close()
                }

                status = "success"
            } catch (e: IOException) {
                e.printStackTrace()
                status = "error"

            }
        }

        pdfFromMultipleImage.invokeOnCompletion {
            GlobalScope.launch(Dispatchers.Main) {
                result.success(pdfImagesPath)
            }
        }
    }



    private fun mergeThemAll(orderImagesList: List<Bitmap>?, maxWidth: Int, maxHeight: Int): Bitmap? {
        var result: Bitmap? = null
        if (orderImagesList != null && orderImagesList.isNotEmpty()) {
            val chunkWidth: Int = orderImagesList[0].width
            val chunkHeight: Int = orderImagesList[0].height

            result = Bitmap.createBitmap(maxWidth, maxHeight *orderImagesList.size, Bitmap.Config.RGB_565)
            Log.d("myTag", "Create Bitmap")
            val canvas = Canvas(result)
            val paint = Paint()
            var chunkHeightCal: Int = 0
            for (i in orderImagesList.indices) {
                canvas.drawBitmap(orderImagesList[i],(0).toFloat(), (chunkHeightCal).toFloat(), paint)
                chunkHeightCal =  chunkHeightCal + maxHeight
            }
        } else {
            Log.e("MergeError", "Couldn't merge bitmaps")
        }
        return result
    }



}