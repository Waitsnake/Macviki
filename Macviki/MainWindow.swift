import Cocoa

class MainWindow: NSWindow {
    
    // Catches the build-in menuitems.
    // Use AppDelegate.validateMenuItem to catch custom menuitems.
//    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
//        if menuItem.action == #selector(NSWindow.toggleFullScreen(_:)) {
//            return true
//        } else {
//            return super.validateMenuItem(menuItem)
//        }
//    }
    
    // Always ensure avoidance is off for fullscreen transition.
    override func toggleFullScreen(_ sender: Any?) {
        (windowController as? WindowController)?.avoidance = .off
        super.toggleFullScreen(sender)
        
        if (windowController as? WindowController)?.fullScr == true
        {
            // disable title bar in window mode
            (windowController as? WindowController)?.fullScr = false
            titleVisibility = .hidden
            titlebarAppearsTransparent = true
            standardWindowButton(.closeButton)?.isHidden = true
            standardWindowButton(.miniaturizeButton)?.isHidden = true
            standardWindowButton(.zoomButton)?.isHidden = true
        }
        else
        {
            // enable title bar in full screen to avoid this white bar that pops in when moving mouse to the top of screen
            (windowController as? WindowController)?.fullScr = true
            titleVisibility = .visible
            titlebarAppearsTransparent = false
            standardWindowButton(.closeButton)?.isHidden = false
            standardWindowButton(.miniaturizeButton)?.isHidden = false
            standardWindowButton(.zoomButton)?.isHidden = false
            
            // always phase in in case off going to fullscreen to avoid cases of phase out
            isOpaque = true
            alphaValue = 1.0
            backgroundColor = NSColor.windowBackgroundColor
            hasShadow = true
            ignoresMouseEvents = false
        }
    }
}
