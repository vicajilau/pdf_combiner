import Cocoa
import FlutterMacOS
import PDFKit

public class PdfCombinerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pdf_combiner", binaryMessenger: registrar.messenger)
        let instance = PdfCombinerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            result("Arguments can't be empty"); return
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
            completionHandler("Arguments 'paths' or 'outputDirPath' can't be empty"); return
        }

        let mergedPDF = PDFDocument()
        var pageIndex = 0
        
        for path in paths {
            guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else { continue }

            for index in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: index) else { continue }
                    mergedPDF.insert(page, at: pageIndex)
                    pageIndex += 1
            }
        }

        guard mergedPDF.write(to: URL(fileURLWithPath: outputDirPath)) else {
            completionHandler("Couldn't save the pdf"); return
        }
        completionHandler(outputDirPath)
    }

    //MARK: Create Pdf from images
    func createPDFFromMultipleImage(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              var height = args["height"] as? Int,
              var width = args["width"] as? Int,
              var keepAspectRatio = args["keepAspectRatio"] as? Bool
        else {
            completionHandler("Arguments 'paths', 'outputDirPath', 'needImageCompressor', 'width' or 'height' can't be empty"); return
        }

        var images = [NSImage]()
        paths.forEach { path in
            guard let image = NSImage(contentsOfFile: path) else {
                completionHandler("Couldn't load image from disk"); return
            }

            if width > 0 && height > 0 && keepAspectRatio {
                images.append(image.resize(width: width))
            } else if width > 0 && height > 0 && !keepAspectRatio {
                images.append(image.resize(width: width, height: height))
            } else {
                images.append(image)
            }
        }

        guard let image = NSImage.mergeVertically(images : images) else {
            completionHandler("Couldn't merge images"); return
        }

        var imageRect = CGRect(origin: .zero, size: image.size)
        let url = URL(fileURLWithPath: outputDirPath) as CFURL
        guard let destContext = CGContext(url, mediaBox: &imageRect, nil),
              let inputCGImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        else {
            completionHandler("Couldn't create context or image for pdf"); return
        }

        destContext.beginPage(mediaBox: nil)
        destContext.draw(inputCGImage, in: imageRect)
        destContext.endPage()
        destContext.closePDF()

        completionHandler(outputDirPath)
    }

    //MARK: Images from pdf.
    func createImageFromPDF(args: Dictionary<String, Any>, completionHandler: @escaping ([String]) -> Void) {
        guard let path = args["path"] as? String,
              let outputDirPath = args["outputDirPath"] as? String,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let compression = args["compression"] as? Int,
              let createOneImage = args["createOneImage"] as? Bool
        else {
            completionHandler(["Arguments 'paths', 'outputDirPath', 'compression', 'createOneImage', 'width' or 'height' can't be empty"]); return
        }
        
        guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else {
            completionHandler(["Couldn't open PDF file"]); return
        }
        
        let compressionQuality = 1.0 - CGFloat(compression) / 100.0
        var pdfImagesPath: [String] = []
        var imagePages: [ImagePage] = []
        let group = DispatchGroup()

        for pageNumber in 0..<pdfDocument.pageCount {
            group.enter()
            guard let pdfPage = pdfDocument.page(at: pageNumber) else {
                group.leave(); continue
            }
            
            let pageRect = pdfPage.bounds(for: .mediaBox)
            let renderSize = pageRect.size

            let image = NSImage(size: renderSize)
            image.lockFocus()
            
            guard let context = NSGraphicsContext.current?.cgContext else {
                image.unlockFocus()
                group.leave()
                continue
            }
            
            context.saveGState()
            // context.translateBy(x: 0, y: renderSize.height)
            // context.scaleBy(x: 1, y: -1)
            pdfPage.draw(with: .mediaBox, to: context)
            context.restoreGState()
            image.unlockFocus()
            
            var resizedImage = image
            if width > 0 && height > 0 {
                resizedImage = image.resize(width: width, height: height)
            }
            
            if !createOneImage {
                if let finalPath = createFileName(path: outputDirPath, with: pageNumber) {
                    do {
                        try resizedImage.save(to: finalPath, quality: compressionQuality)
                        pdfImagesPath.append(finalPath.absoluteString)
                    } catch {}
                }
            } else {
                imagePages.append(.init(page: pageNumber, image: resizedImage))
            }
            group.leave()
        }

        group.notify(queue: .global()) { [weak self] in
            if createOneImage {
                let images = imagePages.sorted { $0.page > $1.page }.map(\.self.image)
                guard let imageMerged = NSImage.mergeVertically(images: images) else {
                    completionHandler(["Couldn't create the images"]); return
                }
                if let finalPath = self?.createFileName(path: outputDirPath) {
                    do {
                        try imageMerged.save(to: finalPath, quality: compressionQuality)
                        pdfImagesPath.append(finalPath.absoluteString)
                    } catch { }
                } else {
                    completionHandler(["Couldn't save the file"]); return
                }
                
            }
            completionHandler(pdfImagesPath)
        }
    }
    
    func createFileName(path: String, with index: Int? = nil) -> URL? {
        var basePath = URL(fileURLWithPath: path)
        guard let index else {
            basePath.appendPathComponent("image_final.jpeg")
            return basePath
        }
        
        let fileName = "image_final_\(index).jpeg"
        basePath.appendPathComponent(fileName)
        return basePath
    }
}
