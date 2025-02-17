import Cocoa
import FlutterMacOS
import ImageIO
import CoreGraphics

public class PdfCombinerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pdf_combiner", binaryMessenger: registrar.messenger)
        let instance = PdfCombinerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            result("Error: Arguments can't be empty"); return
        }

        switch call.method {
        case "mergeMultiplePDF":
            DispatchQueue.global().async { [weak self] in
                self?.mergeMultiplePDF(args: args) { pathToFile in
                    DispatchQueue.main.sync {
                        result(pathToFile)
                    }
                }
            }
        case "createPDFFromMultipleImage":
            DispatchQueue.global().async { [weak self] in
                self?.createPDFFromMultipleImage(args: args) { pathToFile in
                    DispatchQueue.main.sync {
                        result(pathToFile)
                    }
                }
            }
        case "createImageFromPDF":
            DispatchQueue.global().async { [weak self] in
                self?.createImageFromPDF(args: args) { pathToFile in
                    DispatchQueue.main.sync {
                        result(pathToFile)
                    }
                }
            }
        default:
            result("Not Implemented")
        }
    }
}

//MARK: - Main functions
private extension PdfCombinerPlugin {
    struct ImagePage {
        let page: Int
        let image: NSImage
    }

    // MARK: Merge multiple pdf.
    func mergeMultiplePDF(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String
        else {
            completionHandler("Error: Arguments 'paths' or 'outputDirPath' can't be empty"); return
        }

        var mediaBox = CGRect.zero
        let url = URL(fileURLWithPath: outputDirPath) as CFURL
        guard let destContext = CGContext(url, mediaBox: &mediaBox, nil) else {
            completionHandler("Error: Creating context for pdf"); return
        }

        for path in paths {
            guard let pdfRef = CGPDFDocument(NSURL(fileURLWithPath: path)) else { continue }

            for index in 1...pdfRef.numberOfPages {
                if let page = pdfRef.page(at: index) {
                    var mediaBox = page.getBoxRect(.mediaBox)
                    destContext.beginPage(mediaBox: &mediaBox)
                    destContext.drawPDFPage(page)
                    destContext.endPage()
                }
            }
        }
        destContext.closePDF()
        completionHandler(outputDirPath)
    }

    // MARK: Create pdf from multiple images
    func createPDFFromMultipleImage(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              let needImageCompressor = args["needImageCompressor"] as? Bool,
              let maxWidth = args["maxWidth"] as? Int,
              let maxHeight = args["maxHeight"] as? Int
        else {
            completionHandler("Error: Arguments 'paths', 'outputDirPath', 'needImageCompressor', 'maxWidth' or 'maxHeight' can't be empty"); return
        }

        var images = [NSImage]()
        paths.forEach { path in
            guard let image = NSImage(contentsOfFile: path) else {
                completionHandler("Error: Loading image from disk"); return
            }

            if needImageCompressor, let resizedImage = image.resize(maxWidth: maxWidth, maxHeight: maxHeight) {
                images.append(resizedImage)
            } else {
                images.append(image)
            }
        }

        guard let image = NSImage.mergeVertically(images : images) else {
            completionHandler("Error: Merging images"); return
        }

        var imageRect = CGRect(origin: .zero, size: image.size)
        let url = URL(fileURLWithPath: outputDirPath) as CFURL
        guard let destContext = CGContext(url, mediaBox: &imageRect, nil),
              let inputCGImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        else {
            completionHandler("Error: Creating context or image for pdf"); return
        }

        destContext.beginPage(mediaBox: nil)
        destContext.draw(inputCGImage, in: imageRect)
        destContext.endPage()
        destContext.closePDF()

        completionHandler(outputDirPath)
    }

    // MARK: Merge one or multiple images from pdf
    func createImageFromPDF(args: Dictionary<String, Any>, completionHandler: @escaping ([String]) -> Void) {
        guard let path = args["path"] as? String,
              let outputDirPath = args["outputDirPath"] as? String,
              let maxWidth = args["maxWidth"] as? Int,
              let maxHeight = args["maxHeight"] as? Int,
              let createOneImage = args["createOneImage"] as? Bool,
              let pdfDocument = CGPDFDocument(NSURL(fileURLWithPath: path) as CFURL)
        else {
            completionHandler([]); return
        }

        var pdfImagesPath: [String] = []
        var imagePages: [ImagePage] = []
        let group = DispatchGroup()

        // Page number starts at 1, not 0
        for pageNumber in 1...pdfDocument.numberOfPages {
            group.enter()
            guard let pdfPage = pdfDocument.page(at: pageNumber) else {
                group.leave(); continue
            }
            // Scale the image improve the final resolution
            let scale = 200 / 72.0
            let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
            let width = Int(mediaBoxRect.width * CGFloat(scale))
            let height = Int(mediaBoxRect.height * CGFloat(scale))

            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 16,
                                          bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else {
                group.leave(); continue
            }

            context.interpolationQuality = .high
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero,
                                size: CGSize(width: width, height: height)))
            context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            context.drawPDFPage(pdfPage)

            if let image = context.makeImage() {
                let convertNSImage = NSImage(cgImage: image, size: .zero)
                if let resizedImage = convertNSImage.resize(maxWidth: maxWidth, maxHeight: maxHeight) {
                    imagePages.append(.init(page: pageNumber, image: resizedImage))
                    if !createOneImage {
                        let finalPath = outputDirPath.renameFileName(with: pageNumber)
                        resizedImage.save(to: finalPath)
                        pdfImagesPath.append(finalPath)
                    }
                }
            }
            group.leave()
        }

        group.notify(queue: .global()) {
            if createOneImage {
                let images = imagePages.sorted { $0.page > $1.page }.map(\.self.image)
                guard let imageMerged = NSImage.mergeVertically(images: images) else {
                    completionHandler([]); return
                }
                pdfImagesPath.append(outputDirPath)
                imageMerged.save(to: outputDirPath)
            }
            completionHandler(pdfImagesPath)
        }
    }
}
