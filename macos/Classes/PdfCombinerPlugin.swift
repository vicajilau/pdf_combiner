import Cocoa
import FlutterMacOS
import ImageIO
import AVFoundation
import CoreGraphics

public class PdfCombinerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pdf_combiner", binaryMessenger: registrar.messenger)
        let instance = PdfCombinerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let args = call.arguments as? Dictionary<String, Any>
        else {
            result("Error: Arguments can't be empty")
            return
        }
        
        switch call.method {
        case "mergeMultiplePDF":
            DispatchQueue.global().async {
                let singlePDFFromMultiplePDF = PdfCombinerPlugin.mergeMultiplePDF(args : args)
                DispatchQueue.main.sync {
                    result(singlePDFFromMultiplePDF)
                }
            }
        case "createPDFFromMultipleImage":
            DispatchQueue.global().async {
                let pdfFromMultipleImage = PdfCombinerPlugin.createPDFFromMultipleImage(args : args)
                DispatchQueue.main.sync {
                    result(pdfFromMultipleImage)
                }
            }
        case "createImageFromPDF":
            DispatchQueue.global().async {
                let imageFromPDF = PdfCombinerPlugin.createImageFromPDF(args : args)
                DispatchQueue.main.sync {
                    result(imageFromPDF)
                }
            }
        default:
            result("Not Implemented")
        }
    }
}

// MARK: - Logic
extension PdfCombinerPlugin {
    // MARK: Merge multiple pdf.
    class func mergeMultiplePDF(args: Dictionary<String, Any>) -> String {
        guard
            let paths = args["paths"] as? [String],
            let outputDirPath = args["outputDirPath"] as? String
        else {
            return "Error: Arguments 'paths' or 'outputDirPath' can't be empty"
        }

        var mediaBox = CGRect.zero
        let url = URL(fileURLWithPath: outputDirPath) as CFURL
        guard
            let destContext = CGContext(url, mediaBox: &mediaBox, nil)
        else {
            return "Error: Creating context for pdf"
        }

        for index in 0 ..< paths.count {
            let pdfFile = paths[index]
            let pdfUrl = NSURL(fileURLWithPath: pdfFile)
            guard
                let pdfRef = CGPDFDocument(pdfUrl)
            else {
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
        return outputDirPath
    }

    // MARK: Create pdf from multiple images
    class func createPDFFromMultipleImage(args: Dictionary<String, Any>) -> String {
        guard
            let paths = args["paths"] as? [String],
            let outputDirPath = args["outputDirPath"] as? String,
            let needImageCompressor = args["needImageCompressor"] as? Bool,
            let maxWidth = args["maxWidth"] as? Int,
            let maxHeight = args["maxHeight"] as? Int
        else {
            return "Error: Arguments 'paths', 'outputDirPath', 'needImageCompressor', 'maxWidth' or 'maxHeight' can't be empty"
        }

        var images = [NSImage]()
        for index in 0 ..< paths.count {
            guard
                let img  = NSImage(contentsOfFile: paths[index])
            else {
                return "Error: Loading image from disk"
            }

            if needImageCompressor {
                let resizedImage = resizeImage(img: img, maxWidthGet: maxWidth, maxHeightGet: maxHeight)
                images.append(resizedImage)
            } else {
                images.append(img)
            }
        }

        guard
            let image = mergeVertically(images : images)
        else {
            return "Error: Merging images"
        }

        var imageRect = CGRect(origin: .zero, size: image.size)
        let url = URL(fileURLWithPath: outputDirPath) as CFURL
        guard
            let destContext = CGContext(url, mediaBox: &imageRect, nil),
            let inputCGImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        else {
            return "Error: Creating context or image for pdf"
        }

        destContext.beginPage(mediaBox: nil)
        destContext.draw(inputCGImage, in: imageRect)
        destContext.endPage()
        destContext.closePDF()

        return outputDirPath
    }
    
    // MARK: Merge one or multiple images from pdf
    class func createImageFromPDF(args: Dictionary<String, Any>) -> [String]? {
        guard
            let path = args["path"] as? String,
            let outputDirPath = args["outputDirPath"] as? String,
            let maxWidth = args["maxWidth"] as? Int,
            let maxHeight = args["maxHeight"] as? Int,
            let createOneImage = args["createOneImage"] as? Bool
        else {
            return nil
        }

        var pdfImagesPath = [String]()

        let pdfUrl = NSURL(fileURLWithPath: path)
        guard
            let pdfDocument = CGPDFDocument(pdfUrl as CFURL)
        else {
            return nil
        }

        var images = [NSImage]()

        DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { index in
            // Page number starts at 1, not 0
            guard
                let pdfPage = pdfDocument.page(at: index + 1)
            else {
                return
            }

            let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
            let scale = 200 / 72.0
            let width = Int(mediaBoxRect.width * CGFloat(scale))
            let height = Int(mediaBoxRect.height * CGFloat(scale))
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue

            guard
                let context = CGContext(data: nil,
                                        width: width,
                                        height: height,
                                        bitsPerComponent: 16,
                                        bytesPerRow: 0,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo)
            else {
                return
            }

            context.interpolationQuality = .high
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            context.drawPDFPage(pdfPage)

            if let image = context.makeImage() {
                let convertNSImage = NSImage(cgImage: image, size: .zero)
                let  resizedImage = resizeImage(img: convertNSImage, maxWidthGet: maxWidth, maxHeightGet: maxHeight)
                images.append(resizedImage)

                if !createOneImage {
                    let finalPath = generateName(for: outputDirPath, for: index)
                    pdfImagesPath.append(finalPath)
                    save(image: resizedImage, path: finalPath)
                }
            }
        }

        if createOneImage {
            guard
                let imageMerged = mergeVertically(images : images)
            else {
                return nil
            }
            pdfImagesPath.append(outputDirPath)
            save(image: imageMerged, path: outputDirPath)
        }

        return pdfImagesPath
    }

    // MARK: Generate new image name with index
    class func generateName(for path: String, for index: Int) -> String {
        var pathComponents = path.components(separatedBy: "/")
        let fileNameComponents = pathComponents.last?.components(separatedBy: ".")
        let newFileName = "\(fileNameComponents?.first ?? "")_\(String(index)).\(fileNameComponents?.last ?? "jpeg")"
        pathComponents.removeLast()
        pathComponents.append(newFileName)
        return pathComponents.joined(separator: "/")
    }
    
    // MARK: Merge images vertically
    class func mergeVertically(images: [NSImage]) -> NSImage? {
        var maxWidth: CGFloat = 0.0
        var maxHeight: CGFloat = 0.0

        for image in images {
            maxHeight += image.size.height
            if image.size.width > maxWidth {
                maxWidth = image.size.width
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * Int(maxWidth)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard
            let context = CGContext(data: nil,
                                    width: Int(maxWidth),
                                    height: Int(maxHeight),
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo.rawValue)
        else {
            print("unable to create context")
            return nil
        }

        var runningHeight: CGFloat = 0.0
        for image in images {
            var imageRect = CGRect(origin: .zero, size: image.size)
            let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
             if let inputCGImage = imageRef  {
                context.draw(inputCGImage,
                             in: CGRect(x: CGFloat(0),
                                        y: runningHeight,
                                        width: image.size.width,
                                        height: image.size.height),
                             byTiling: false)
                runningHeight += image.size.height
             }
        }

        guard
            let outputCGImage = context.makeImage()
        else {
            return nil
        }
        return NSImage(cgImage: outputCGImage, size: .zero)
    }

    // MARK: Resize images
    class func resizeImage(img: NSImage, maxWidthGet : Int, maxHeightGet : Int) -> NSImage {
        var actualHeight: Float = Float(img.size.height)
        var actualWidth: Float = Float(img.size.width)
        let maxHeight: Float = Float(maxHeightGet)
        let maxWidth: Float = Float(maxWidthGet)
        var imgRatio: Float = actualWidth / actualHeight
        let maxRatio: Float = maxWidth / maxHeight

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

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        img.draw(in: CGRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        newImage.size = newSize

        return NSImage(data: newImage.tiffRepresentation!)!
    }
    
    // MARK: Sava image to disk
    class func save(image: NSImage, path: String) {
        guard
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return
        }

        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = image.size
        guard
            let data = imageRep.representation(using: .jpeg, properties: [:])
        else {
            return
        }

        let urlOutputDirPath = URL.init(fileURLWithPath: path)
        do {
            try data.write(to: urlOutputDirPath, options: .atomic)
        } catch {
            print("Unable to save image")
        }
    }
}
