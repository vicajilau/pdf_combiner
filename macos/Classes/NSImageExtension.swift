import Foundation
import AVFoundation

extension NSImage {
    func resize(maxWidth: Int, maxHeight: Int) -> NSImage? {
        var actualHeight = Float(self.size.height)
        var actualWidth = Float(self.size.width)
        let maxHeight = Float(maxHeight)
        let maxWidth = Float(maxWidth)
        var imgRatio = Float(actualWidth / actualHeight)
        let maxRatio = Float(maxWidth / maxHeight)

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

        let rect = CGRect(origin: .zero,
                          size: CGSize(width: CGFloat(actualWidth),
                                       height: CGFloat(actualHeight)))
        let newSize = AVMakeRect(aspectRatio: self.size, insideRect: rect).size

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: CGRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        newImage.size = newSize

        guard
            let imageData = newImage.tiffRepresentation
        else {
            return nil
        }
        
        return NSImage(data: imageData)
    }
    
    // MARK: Merge images vertically
    static func mergeVertically(images: [NSImage]) -> NSImage? {
        var maxWidth: CGFloat = .zero
        var maxHeight: CGFloat = .zero

        for image in images {
            maxHeight += image.size.height
            if image.size.width > maxWidth {
                maxWidth = image.size.width
            }
        }

        guard
            let context = CGContext(data: nil,
                                    width: Int(maxWidth),
                                    height: Int(maxHeight),
                                    bitsPerComponent: 16,
                                    bytesPerRow: 0,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            return nil
        }

        var runningHeight: CGFloat = .zero
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

        guard let outputCGImage = context.makeImage() else { return nil }
        return NSImage(cgImage: outputCGImage, size: .zero)
    }
    
    // MARK: Sava image to disk
    func save(to path: String) {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = size
        
        guard let data = imageRep.representation(using: .jpeg, properties: [:]) else { return }
        let urlOutputDirPath = URL.init(fileURLWithPath: path)
        
        try? data.write(to: urlOutputDirPath, options: .atomic)
    }
}
