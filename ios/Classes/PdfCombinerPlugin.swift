import Flutter
import UIKit
import MobileCoreServices
import ImageIO

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

    func mergeMultiplePDF(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              UIGraphicsBeginPDFContextToFile(outputDirPath, .zero, nil),
              let destContext = UIGraphicsGetCurrentContext()
        else {
            completionHandler("Error: Arguments 'paths' or 'outputDirPath' can't be empty or couldn't create context for pdf"); return
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

    func createPDFFromMultipleImage(args: Dictionary<String, Any>, completionHandler: @escaping (String) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              let needImageCompressor = args["needImageCompressor"] as? Bool,
              let maxWidth = args["maxWidth"] as? Int,
              let maxHeight = args["maxHeight"] as? Int,
              UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil)
        else {
            completionHandler("Error: Arguments 'paths', 'outputDirPath', 'needImageCompressor', 'maxWidth' or 'maxHeight' can't be empty"); return
        }

        var images: [UIImage] = []
        for path in paths {
            guard let image = UIImage(contentsOfFile: path) else {
                completionHandler("Error: Loading image from disk: \(path)"); return
            }
            if needImageCompressor {
                let resizedImage = image.resize(maxWidth: maxWidth, maxHeight: maxHeight)
                images.append(resizedImage)
            } else {
                images.append(image)
            }
        }

        guard let image = UIImage.mergeVertically(images : images) else {
            completionHandler("Error: Merging images"); return
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
            let maxWidth = args["maxWidth"] as? Int,
            let maxHeight = args["maxHeight"] as? Int,
            let createOneImage = args["createOneImage"] as? Bool,
            let pdfDocument = CGPDFDocument(NSURL(fileURLWithPath: path) as CFURL),
            UIGraphicsBeginPDFContextToFile(outputDirPath, CGRect.zero, nil)
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

            let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
            let scale = 200 / 72.0
            let width = Int(mediaBoxRect.width * CGFloat(scale))
            let height = Int(mediaBoxRect.height * CGFloat(scale))

            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 16,
                                          bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else {
                group.leave(); continue
            }

            context.interpolationQuality = .high
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(x: .zero, y: .zero, width: width, height: height))
            context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            context.drawPDFPage(pdfPage)

            if let image = context.makeImage() {
                let convertUIImage = UIImage(cgImage: image)
                let resizedImage = convertUIImage.resize(maxWidth: maxWidth, maxHeight: maxHeight)

                imagePages.append(.init(page: pageNumber, image: resizedImage))

                if !createOneImage {
                    let finalPath = outputDirPath.renameFileName(with: pageNumber)
                    pdfImagesPath.append(finalPath)
                    let urlOutputDirPath = NSURL(fileURLWithPath: finalPath)
                    if let imageDestination = CGImageDestinationCreateWithURL(urlOutputDirPath as CFURL, kUTTypePNG, 1, nil) {
                        CGImageDestinationAddImage(imageDestination, resizedImage.cgImage ?? image, nil)
                        CGImageDestinationFinalize(imageDestination)
                    }
                }
            }
            group.leave()
        }

        group.notify(queue: .global()) {
            if createOneImage {
                let images = imagePages.sorted { $0.page < $1.page }.map(\.self.image)
                guard let image = UIImage.mergeVertically(images : images) else {
                    completionHandler([]); return
                }

                pdfImagesPath.append(outputDirPath)
                let urlOutputDirPath = NSURL(fileURLWithPath: outputDirPath)

                guard let imageDestination = CGImageDestinationCreateWithURL(urlOutputDirPath as CFURL,kUTTypePNG, 1, nil),
                      let inputImage = image.cgImage
                else {
                    completionHandler([]); return
                }

                CGImageDestinationAddImage(imageDestination, inputImage, nil)
                CGImageDestinationFinalize(imageDestination)
            }

            completionHandler(pdfImagesPath)
        }
    }
}
