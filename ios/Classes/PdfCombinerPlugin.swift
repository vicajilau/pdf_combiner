import Flutter
import UIKit
import MobileCoreServices
import ImageIO
import AVFoundation

public class PdfCombinerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pdf_combiner", binaryMessenger: registrar.messenger())
        let instance = PdfCombinerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "mergeMultiplePDF" {
            if let args = call.arguments as? Dictionary<String, Any>{
                DispatchQueue.global().async {
                    let singlePDFFromMultiplePDF =  PdfCombinerPlugin.mergeMultiplePDF(args : args)
                    DispatchQueue.main.sync {
                        result(singlePDFFromMultiplePDF)
                    }
                }
            } else {
                result("error")
            }
        } else if call.method == "createPDFFromMultipleImage" {
            if let args = call.arguments as? Dictionary<String, Any>{
                DispatchQueue.global().async {
                    let pdfFromMultipleImage = PdfCombinerPlugin.createPDFFromMultipleImage(args : args)
                    DispatchQueue.main.sync {
                        result(pdfFromMultipleImage)
                    }
                }
            } else {
                result("error")
            }
        } else if call.method == "createImageFromPDF" {
            if let args = call.arguments as? Dictionary<String, Any> {
                DispatchQueue.global().async {
                    let imageFromPDF = PdfCombinerPlugin.createImageFromPDF(args : args)
                    DispatchQueue.main.sync {
                        result(imageFromPDF)
                    }
                }
            } else {
                result("error")
            }
        } else{
            result("Not Implemented")
        }
    }
    
    class func mergeMultiplePDF(args: Dictionary<String, Any>) -> String? {
        if let paths = args["paths"] as? [String], let outputDirPath = args["outputDirPath"] as? String {
            guard UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil) else {
                return "error"
            }
            guard let destContext = UIGraphicsGetCurrentContext() else {
                return "error"
            }
            
            for index in 0 ..< paths.count {
                let pdfFile = paths[index]
                let pdfUrl = NSURL(fileURLWithPath: pdfFile)
                guard let pdfRef = CGPDFDocument(pdfUrl) else {
                    continue
                }
                
                for i in 1 ... pdfRef.numberOfPages {
                    if let page = pdfRef.page(at: i) {
                        var mediaBox = page.getBoxRect(.mediaBox)
                        destContext.beginPage(mediaBox: &mediaBox)
                        destContext.drawPDFPage(page)
                        destContext.endPage()
                    }
                }
            }
            
            destContext.closePDF()
            UIGraphicsEndPDFContext()
            
            return outputDirPath
        }
        return "error"
    }
    
    class func createPDFFromMultipleImage(args: Dictionary<String, Any>) -> String? {
        if let paths = args["paths"] as? [String], let outputDirPath = args["outputDirPath"] as? String
            , let needImageCompressor = args["needImageCompressor"] as? Bool
            , let maxWidth = args["maxWidth"] as? Int
            , let maxHeight = args["maxHeight"] as? Int{
            
            guard UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil) else {
                return "error"
            }
            
            var images = [UIImage]()
            
            for index in 0 ..< paths.count {
                guard let  img  = UIImage(contentsOfFile: paths[index])  else { return "error" }
                if needImageCompressor {
                    let resizedImage = resizeImage(img : img, maxWidthGet : maxWidth, maxHeightGet : maxHeight)
                    images.append(resizedImage)
                } else {
                    images.append(img)
                }
            }

            guard let  image = mergeVertically(images : images) else {  return "error" }
            let pdfData = NSMutableData()
            let imgView = UIImageView.init(image: image)
            let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            UIGraphicsBeginPDFContextToData(pdfData, imageRect, nil)
            UIGraphicsBeginPDFPage()
            let context = UIGraphicsGetCurrentContext()
            imgView.layer.render(in: context!)
            UIGraphicsEndPDFContext()
            
            let urlOutputDirPath = URL.init(fileURLWithPath: outputDirPath)
            
            do {
                try pdfData.write(to: urlOutputDirPath, options: NSData.WritingOptions.atomic)
            } catch {
                return "error"
            }
            
            return outputDirPath
        }
        
        return "error"
    }
    
    class func createImageFromPDF(args: Dictionary<String, Any>) -> [String]? {
        
        var pdfImagesPath = [String]()
        
        if let path = args["path"] as? String, let outputDirPath = args["outputDirPath"] as? String
            , let maxWidth = args["maxWidth"] as? Int
            , let maxHeight = args["maxHeight"] as? Int
            , let createOneImage = args["createOneImage"] as? Bool{
            
            guard UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil) else {
                return nil
            }
            
            let pdfUrl = NSURL(fileURLWithPath: path)
            
            let pdfDocument = CGPDFDocument(pdfUrl as CFURL)!
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
            var images = [UIImage]()
            
            DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { i in
                // Page number starts at 1, not 0
                let pdfPage = pdfDocument.page(at: i + 1)!
                
                let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
                let scale = 200 / 72.0
                let width = Int(mediaBoxRect.width * CGFloat(scale))
                let height = Int(mediaBoxRect.height * CGFloat(scale))
                
                let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 16, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
                context.interpolationQuality = .high
                context.setFillColor(UIColor.white.cgColor)
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
                context.drawPDFPage(pdfPage)
                
                let image = context.makeImage()!
                
                let convertUIImage = UIImage(cgImage: image)
                
                let  resizeUIImage =  resizeImage(img : convertUIImage, maxWidthGet : maxWidth, maxHeightGet : maxHeight)
                
                images.append(resizeUIImage)
                
                if !createOneImage {
                    
                    let pathName = outputDirPath.components(separatedBy: ".")
                    let finalPath = pathName[0] + String(i) + "." + pathName[1]

                    pdfImagesPath.append(finalPath)

                    let urlOutputDirPath = NSURL(fileURLWithPath: finalPath)
                    let imageDestination = CGImageDestinationCreateWithURL(urlOutputDirPath as CFURL,kUTTypePNG, 1, nil)!
                    
                    CGImageDestinationAddImage(imageDestination, resizeUIImage.cgImage ?? image, nil)
                    CGImageDestinationFinalize(imageDestination)
                }
            }
            
            if createOneImage {
                guard let  image = mergeVertically(images : images) else {  return nil }
                
                pdfImagesPath.append(outputDirPath)
                let urlOutputDirPath = NSURL(fileURLWithPath: outputDirPath)
                
                let imageDestination = CGImageDestinationCreateWithURL(urlOutputDirPath as CFURL,kUTTypePNG, 1, nil)!
                
                guard let inputImage = image.cgImage else {  return nil }
                
                CGImageDestinationAddImage(imageDestination, inputImage, nil)
                CGImageDestinationFinalize(imageDestination)
            }
            
            return pdfImagesPath
        }
        
        return nil
    }

    public static func mergeVertically(images: [UIImage]) -> UIImage? {
        var maxWidth:CGFloat = 0.0
        var maxHeight:CGFloat = 0.0

        for image in images {
            maxHeight += image.size.height
            if image.size.width > maxWidth {
                maxWidth = image.size.width
            }
        }
        
        let finalSize = CGSize(width: maxWidth, height: maxHeight)
        
        UIGraphicsBeginImageContext(finalSize)
        
        var runningHeight: CGFloat = 0.0
        
        for image in images {
            image.draw(in: CGRect(x: 0.0, y: runningHeight, width: image.size.width, height: image.size.height))
            runningHeight += image.size.height
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return finalImage!
    }
    
    public static func resizeImage(img: UIImage, maxWidthGet : Int, maxHeightGet : Int) -> UIImage {
        var actualHeight: Float = Float(img.size.height)
        var actualWidth: Float = Float(img.size.width)
        let maxHeight: Float = Float(maxHeightGet)
        let maxWidth: Float = Float(maxWidthGet)
        var imgRatio: Float = actualWidth / actualHeight
        let maxRatio: Float = maxWidth / maxHeight
        //        let compressionQuality: Float = 0.5
        //50 percent compression
        
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            } else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        
        let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(actualWidth),  height: CGFloat(actualHeight))
        let newSize = AVMakeRect( aspectRatio: img.size, insideRect: rect).size
        
        //        UIGraphicsBeginImageContext(rect.size)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        img.draw(in: CGRect(origin: .zero, size: newSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext() ?? img
        UIGraphicsEndImageContext()
        
        //        img.draw(in:rect)
        //        let img = UIGraphicsGetImageFromCurrentImageContext()
        //        let imageData = img?.jpegData(compressionQuality: CGFloat(compressionQuality))
        //        UIGraphicsEndImageContext()
        return scaled
    }
    
    public static func covertToFileString(size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["(bytes)", "(KB)", "(MB)", "(GB)", "(TB)", "(PB)",  "(EB)",  "(ZB)", "(YB)"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
    
}
