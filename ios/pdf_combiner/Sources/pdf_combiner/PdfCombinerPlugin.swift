import Flutter
import UIKit
import PDFKit

public class PdfCombinerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pdf_combiner", binaryMessenger: registrar.messenger())
        let instance = PdfCombinerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            result(PDFCombinerErrors.wrongArguments(["FlutterMethodCall.arguments"]).flutterError); return
        }

        switch call.method {
        case "mergeMultiplePDF":
            DispatchQueue.global().async { [weak self] in
                self?.mergeMultiplePDF(args: args) { operation in
                    DispatchQueue.main.sync {
                        switch operation {
                        case .success(let pathToFile):
                            result(pathToFile)
                        case .failure(let error):
                            result(error.flutterError)
                        }
                    }
                }
            }
        case "createPDFFromMultipleImage":
            DispatchQueue.global().async { [weak self] in
                self?.createPDFFromMultipleImage(args : args) { operation in
                    DispatchQueue.main.sync {
                        switch operation {
                        case .success(let pathToFile):
                            result(pathToFile)
                        case .failure(let error):
                            result(error.flutterError)
                        }
                    }
                }
            }
        case "createImageFromPDF":
            DispatchQueue.global().async { [weak self] in
                self?.createImageFromPDF(args : args) { operation in
                    DispatchQueue.main.sync {
                        switch operation {
                        case .success(let pathToFile):
                            result(pathToFile)
                        case .failure(let error):
                            result(error.flutterError)
                        }
                    }
                }
            }
        default:
            result(PDFCombinerErrors.notImplemented.flutterError)
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
    func mergeMultiplePDF(args: Dictionary<String, Any>, completionHandler: @escaping (Result<String, PDFCombinerErrors>) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String
        else {
            completionHandler(.failure(PDFCombinerErrors.wrongArguments(["paths", "outputDirPath"]))); return
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
            completionHandler(.failure(PDFCombinerErrors.canNotWriteFile(outputDirPath))); return
        }
        completionHandler(.success(outputDirPath))
    }

    //MARK: Create Pdf from images
    func createPDFFromMultipleImage(args: Dictionary<String, Any>, completionHandler: @escaping (Result<String, PDFCombinerErrors>) -> Void) {
        guard let paths = args["paths"] as? [String],
              let outputDirPath = args["outputDirPath"] as? String,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let keepAspectRatio = args["keepAspectRatio"] as? Bool
        else {
            completionHandler(.failure(PDFCombinerErrors.wrongArguments(["paths", "outputDirPath", "width", "height", "keepAspectRatio"]))); return
        }
        
        var images: [UIImage] = []
        for path in paths {
            guard let image = UIImage(contentsOfFile: path) else {
                completionHandler(.failure(PDFCombinerErrors.canNotReadFile(path))); return
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
            completionHandler(.failure(PDFCombinerErrors.generatePDFFailed)); return
        }

        let imageRect = CGRect(origin: .zero,
                               size: CGSize(width: image.size.width, height: image.size.height))

        UIGraphicsBeginPDFContextToFile(outputDirPath, imageRect, nil)
        UIGraphicsBeginPDFPage()
        image.draw(at: .zero)
        UIGraphicsEndPDFContext()

        completionHandler(.success(outputDirPath))
    }

    //MARK: Images from pdf.
    func createImageFromPDF(args: Dictionary<String, Any>, completionHandler: @escaping (Result<[String], PDFCombinerErrors>) -> Void) {
        guard let path = args["path"] as? String,
              let outputDirPath = args["outputDirPath"] as? String,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let compression = args["compression"] as? Int,
              let createOneImage = args["createOneImage"] as? Bool
        else {
            completionHandler(.failure(PDFCombinerErrors.wrongArguments(["path", "outputDirPath", "width", "height", "compression", "createOneImage"]))); return
        }

        guard let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) else {
            completionHandler(.failure(PDFCombinerErrors.canNotReadFile(path))); return
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
                   let jpgData = resizedImage.jpegData(compressionQuality: compressionQuality),
                   let pngData = UIImage(data: jpgData)?.pngData() {
                    do {
                        try pngData.write(to: fileURL)
                        pdfImagesPath.append(fileURL.relativePath)
                    } catch { }
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
                    completionHandler(.failure(PDFCombinerErrors.generatePDFFailed)); return
                }

                if let fileURL = self?.createFileName(path: outputDirPath),
                   let data = image.jpegData(compressionQuality: compressionQuality) {
                    pdfImagesPath.append(fileURL.relativePath)
                    do {
                        try data.write(to: fileURL)
                    } catch {
                        completionHandler(.failure(PDFCombinerErrors.canNotWriteFile(fileURL.absoluteString))); return
                    }
                    
                }
            }
            completionHandler(.success(pdfImagesPath))
        }
    }
}

//MARK: - Auxiliary functions

extension FlutterError: Swift.Error {}

private extension PdfCombinerPlugin {
    enum PDFCombinerErrors: Error {
        case notImplemented
        case canNotReadFile(String)
        case canNotWriteFile(String)
        case wrongArguments([String])
        case generatePDFFailed
        
        var flutterError: FlutterError {
            let code: String
            var message: String? = nil
            switch self {
            case .notImplemented:
                code = "NotImplemented"
                message = "Not implemented operation."
            case .canNotReadFile(let file):
                code = "CanNotReadFile"
                message = "Couldn't read file \(file)"
            case .canNotWriteFile(let file):
                code = "CanNotWriteFile"
                message = "Couldn't save file \(file)"
            case .generatePDFFailed:
                code = "GeneratePDFFailed"
                message = "Couldn't create the final PDF"
            case let .wrongArguments(arguments):
                code = "WrongArguments"
                message = "Missing or wrong arguments: \(arguments.joined(separator: " - "))"
            }
            
            return FlutterError(code: code, message: message, details: UIDevice.current.deviceInfo)
        }
        
    }
    
    func createFileName(path: String, with index: Int? = nil) -> URL? {
        var basePath = URL(fileURLWithPath: path)
        guard let index else {
            basePath.appendPathComponent("image.png")
            return basePath
        }
        
        let fileName = "image_\(index + 1).png"
        basePath.appendPathComponent(fileName)
        return basePath
    }
}

extension UIDevice {
    var deviceInfo: [String: String] {
        let device = UIDevice.current
        let info = Bundle.main.infoDictionary
        
        return [
            "deviceModel": device.model,
            "deviceName": device.name,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "appVersion": info?["CFBundleShortVersionString"] as? String ?? "N/A",
            "buildVersion": info?["CFBundleVersion"] as? String ?? "N/A"
        ]
    }
}
