import Flutter
import UIKit
import MobileCoreServices
import ImageIO
import PDFKit

public class PdfCombinerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pdf_combiner", binaryMessenger: registrar.messenger())
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
                self?.createPDFFromMultipleImage(args : args) { pathToFile in
                    DispatchQueue.main.sync {
                        result(pathToFile)
                    }
                }
            }
        case "createImageFromPDF":
            DispatchQueue.global().async { [weak self] in
                self?.createImageFromPDF(args : args) { pathToFile in
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
        let image: UIImage
    }
    
    //MARK: Merge Pdfs
    func mergeMultiplePDF(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              UIGraphicsBeginPDFContextToFile(outputDirPath, .zero, nil),
              let destContext = UIGraphicsGetCurrentContext()
        else {
            completionHandler("Arguments 'paths' or 'outputDirPath' can't be empty or couldn't create context for pdf"); return
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
        UIGraphicsEndPDFContext()

        completionHandler(outputDirPath)
    }

    //MARK: Create Pdf from images
    func createPDFFromMultipleImage(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              let height = args["height"] as? Int,
              let width = args["width"] as? Int,
              let keepAspectRatio = args["keepAspectRatio"] as? Bool,
              UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil)
        else {
            completionHandler("Arguments 'paths', 'outputDirPath', 'needImageCompressor', 'width' or 'height' can't be empty"); return
        }

        var images: [UIImage] = []
        for path in paths {
            guard let image = UIImage(contentsOfFile: path) else {
                completionHandler("Can't load image from disk: \(path)"); return
            }
            
            if width > 0 && height > 0 && keepAspectRatio {
                images.append(image.resize(width: width))
            } else if width > 0 && height > 0 && !keepAspectRatio {
                images.append(image.resize(width: width, height: height))
            } else {
                images.append(image)
            }
        }

        guard let image = UIImage.mergeVertically(images : images) else {
            completionHandler("Can't merge images"); return
        }

        let imageRect = CGRect(origin: .zero,
                               size: CGSize(width: image.size.width, height: image.size.height))

        UIGraphicsBeginPDFContextToFile(outputDirPath, imageRect, nil)
        UIGraphicsBeginPDFPage()
        image.draw(at: .zero)
        UIGraphicsEndPDFContext()

        completionHandler(outputDirPath)
    }

    func createImageFromPDF(args: Dictionary<String, Any>, completionHandler: @escaping ([String]) -> Void) {
        guard
            let path = args["path"] as? String,
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
        
        let compressionQuality = CGFloat(compression) / 100.0
        var pdfImagesPath: [String] = []
        var imagePages: [ImagePage] = []
        let group = DispatchGroup()

        // Page number starts at 1, not 0
        for pageNumber in 1...pdfDocument.pageCount {
            group.enter()
            guard let pdfPage = pdfDocument.page(at: pageNumber) else {
                group.leave(); continue
            }
            
            let mediaBoxRect = pdfPage.bounds(for: .mediaBox)
            let renderSize = mediaBoxRect.size
            
            let renderer = UIGraphicsImageRenderer(size: renderSize)
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: renderSize))
                let cgContext = context.cgContext
                cgContext.translateBy(x: 0.0, y: renderSize.height)
                cgContext.scaleBy(x: 1, y: -1)
                
                pdfPage.draw(with: .mediaBox, to: cgContext)
            }
            
            var resizedImage = image
            if width > 0 && height > 0 {
                resizedImage = image.resize(width: width, height: height)
            }
            
            if !createOneImage {
                if let fileURL = createFileName(path: outputDirPath, with: pageNumber),
                   let data = resizedImage.jpegData(compressionQuality: compressionQuality) {
                    pdfImagesPath.append(fileURL.absoluteString)
                    do {
                        try data.write(to: fileURL)
                    } catch {
                        print(error)
                    }
                }
            } else {
                imagePages.append(.init(page: pageNumber, image: resizedImage))
            }
            group.leave()
        }

        group.notify(queue: .global()) { [weak self] in
            if createOneImage {
                let images = imagePages.sorted { $0.page < $1.page }.map(\.self.image)
                guard let image = UIImage.mergeVertically(images : images) else {
                    completionHandler(["Couldn't create the images"]); return
                }

                if let fileURL = self?.createFileName(path: outputDirPath),
                   let data = image.jpegData(compressionQuality: compressionQuality) {
                    pdfImagesPath.append(fileURL.absoluteString)
                    do {
                        try data.write(to: fileURL)
                    } catch {
                        print(error)
                    }
                    
                }
            }
            completionHandler(pdfImagesPath)
        }
    }
    
    func createFileName(path: String, with index: Int? = nil) -> URL? {
        var basePath = URL(fileURLWithPath: path)
        guard let index else {
            basePath.appendPathComponent("image.jpeg")
            return basePath
        }
        
        let fileName = "image_\(index).jpeg"
        basePath.appendPathComponent(fileName)
        return basePath
    }
}
