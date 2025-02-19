import Foundation

extension String {
    func renameFileName(with index: Int) -> String {
        guard let documentUrl = URL(string: self) else { return "" }
        let fileName = documentUrl.lastPathComponent
        var basePath = documentUrl.deletingLastPathComponent()
        let fileNameComponents = fileName.components(separatedBy: ".")
        let newFileName = "\(fileNameComponents.first ?? "")_\(index).\(fileNameComponents.last ?? "jpeg")"
        basePath.appendPathComponent(newFileName)
        return basePath.absoluteString
    }
}
