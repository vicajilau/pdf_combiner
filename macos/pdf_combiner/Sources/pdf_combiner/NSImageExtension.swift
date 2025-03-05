import AppKit
import AVFoundation

extension NSImage {
    /// Merge vertically a list of images
    ///
    /// - Parameters:
    ///   - images: List of images
    /// - Returns: New image
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
    
    /// Resize an image if its width or height is bigger to maxWidth or maxHeight keeping its aspect ratio
    ///
    /// - Parameters:
    ///   - maxWidth: Maximum width
    ///   - maxHeight: Maximum height
    /// - Returns: New resized image
    func resize(maxWidth: Int, maxHeight: Int) -> NSImage? {
        var actualHeight = Float(size.height)
        var actualWidth = Float(size.width)
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
        defer { newImage.unlockFocus() }
        
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        
        return newImage
    }
    
    /// Resize an image to a specific width and height. This function does NOT keep the aspect ratio of the original image.
    ///
    /// - Parameters:
    ///   - width: New width
    ///   - height: New height
    /// - Returns: New resized image
    func resize(width: Int, height: Int) -> NSImage {
        let newSize = NSSize(width: width,
                             height: height)
        
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        
        return newImage
    }
       
    /// Resize an image to a specific width keeping the aspect ratio of the original image.
    ///
    /// - Parameters:
    ///   - width: New width
    /// - Returns: New resized image
    func resize(width: Int) -> NSImage {
        let scaleFactor = CGFloat(width) / size.width
        let newSize = NSSize(width: size.width * scaleFactor,
                             height: size.height * scaleFactor)
        
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        
        return newImage
    }
    
    ///
    /// - Parameters:
    ///   - path: Image name with absolute path
    func save(to path: URL, quality: Double) throws {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        else { return }
        
        try data.write(to: path)
    }
}
