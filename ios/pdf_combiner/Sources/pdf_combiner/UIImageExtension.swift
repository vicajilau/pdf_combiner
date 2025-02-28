import UIKit
import AVFoundation

extension UIImage {
    /// Merge vertically a list of images
    ///
    /// - Parameters:
    ///   - images: List of images
    /// - Returns: New image
    static func mergeVertically(images: [UIImage]) -> UIImage? {
        var maxWidth: CGFloat = .zero
        var maxHeight: CGFloat = .zero

        for image in images {
            maxHeight += image.size.height
            if image.size.width > maxWidth {
                maxWidth = image.size.width
            }
        }
        
        let finalSize = CGSize(width: maxWidth, height: maxHeight)
        
        UIGraphicsBeginImageContext(finalSize)
        var runningHeight: CGFloat = .zero
        for image in images {
            image.draw(in: CGRect(x: .zero, y: runningHeight, width: image.size.width, height: image.size.height))
            runningHeight += image.size.height
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    /// Resize an image if its width or height is bigger to maxWidth or maxHeight keeping its aspect ratio
    ///
    /// - Parameters:
    ///   - maxWidth: Maximum width
    ///   - maxHeight: Maximum height
    /// - Returns: New resized image
    func resize(maxWidth: Int, maxHeight: Int) -> UIImage {
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
        let newSize = AVMakeRect(aspectRatio: size, insideRect: rect).size
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, .zero)
        draw(in: CGRect(origin: .zero, size: newSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaled
    }
    
    /// Resize an image to a specific width and height. This function does NOT keep the aspect ratio of the original image.
    ///
    /// - Parameters:
    ///   - width: New width
    ///   - height: New height
    /// - Returns: New resized image
    func resize(width: Int, height: Int) -> UIImage {
        let targetSize = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Resize an image to a specific width keeping the aspect ratio of the original image.
    ///
    /// - Parameters:
    ///   - width: New width
    /// - Returns: New resized image
    func resize(width: Int) -> UIImage {
        let scaleFactor = CGFloat(width) / size.width
        let newSize = CGSize(width: size.width * scaleFactor,
                             height: size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
