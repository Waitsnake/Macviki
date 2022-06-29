import Foundation

struct Util {
    static let minWindowSize = NSSize(width: 320, height: 180)
    static let defaultWindowFrame = NSRect(x: 100, y: 100, width: 480, height: 270)
    static let defaultPath = "/v1/explore"
    
    // Never enlarges the frame to achieve the aspect ratio.
    // Also centers the output frame.
    static func scaleFrameToAspectRatio(aspect: NSSize, frame: NSRect) -> NSRect {
        let targetRatio = aspect.width / aspect.height
        let origRatio = frame.width / frame.height
        
        var newHeight: CGFloat = frame.height
        var newWidth: CGFloat = frame.width
        if targetRatio > origRatio {
            newHeight = frame.width / targetRatio
        } else {
            newWidth = frame.height * targetRatio
        }
        
        let newX = frame.midX - newWidth / 2
        let newY = frame.midY - newHeight / 2
        return NSRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}
