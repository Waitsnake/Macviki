import Cocoa

class MainWindow: NSWindow {
        
    // Always ensure avoidance is off for fullscreen transition.
    override func toggleFullScreen(_ sender: Any?) {
        (windowController as? WindowController)?.avoidance = .off
        super.toggleFullScreen(sender)
        
        // check if we exit tile mode
        if (windowController as? WindowController)?.tileScr == true
        {
            // disable title bar in window mode when exit tile mode
            (windowController as? WindowController)?.tileScr = false
            titleVisibility = .hidden
            titlebarAppearsTransparent = true
            standardWindowButton(.closeButton)?.isHidden = true
            standardWindowButton(.miniaturizeButton)?.isHidden = true
            standardWindowButton(.zoomButton)?.isHidden = true
        }
        else
        {
            // we enter or exit fullscreen mode
            
            if (windowController as? WindowController)?.fullScr == true
            {
                // disable title bar in window mode when exit fullscreen mode
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
                
                // always phase-in in case off going to fullscreen to avoid cases of phase-out
                isOpaque = true
                alphaValue = 1.0
                backgroundColor = NSColor.windowBackgroundColor
                hasShadow = true
                ignoresMouseEvents = false
            }
        }
    }
}
