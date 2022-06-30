import Cocoa

// The root / catch-all content view of the main window.
class RootView: NSView {
    // Note: Using NSApp.sendAction() didn't work because of, I believe,
    // the responder chain not including the window when the app is not focused.
    override func mouseExited(with event: NSEvent) {
        (window?.windowController as? WindowController)?.phaseIn()
        // disable menu buttons if window is left by mouse (only in normal mode (not ghost nor fullscreen nor tile mode)
        if ((window?.windowController as? WindowController)?.tileScr == false &&
            (window?.windowController as? WindowController)?.fullScr == false && (window?.windowController as? WindowController)?.avoidance == .off)
        {
            window?.standardWindowButton(.closeButton)?.isHidden = true
            window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window?.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        (window?.windowController as? WindowController)?.phaseOut()
        // enable menu buttons if window is entered by mouse (only in normal mode (not ghost nor fullscreen nor tile mode)
        if ((window?.windowController as? WindowController)?.tileScr == false &&
            (window?.windowController as? WindowController)?.fullScr == false && (window?.windowController as? WindowController)?.avoidance == .off)
        {
            window?.standardWindowButton(.closeButton)?.isHidden = false
            window?.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window?.standardWindowButton(.zoomButton)?.isHidden = false
        }
    }
    
    override func updateTrackingAreas() {
        for area in self.trackingAreas {
            self.removeTrackingArea(area)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .mouseMoved
        ]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}
