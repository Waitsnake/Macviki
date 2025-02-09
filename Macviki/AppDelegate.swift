import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var window: MainWindow!
    var webView: DraggableWebView!
    var windowController = WindowController()
    var fullscr: Bool!
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return false }
        switch action {
        case #selector(AppDelegate.toggleAlwaysTop(_:)):
            return true
        case #selector(AppDelegate.toggleHideOnHover(_:)):
            // Only enabled if not fullscreened.
            return !window.styleMask.contains(.fullScreen)
        default:
            // Enable the rest of our custom menuitems for now.
            return true
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let styleMask = NSWindow.StyleMask(arrayLiteral: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView])
        let frame = Store.getWindowFrame()
        window = MainWindow(contentRect: frame, styleMask: styleMask, backing: NSWindow.BackingStoreType.buffered, defer: true, screen: NSScreen.main)
        //window.setFrame(frame, display: true)
        window.windowController = windowController
        window.delegate = windowController
        windowController.window = window
        window.contentView = RootView()
        window.minSize = Util.minWindowSize
        window.collectionBehavior = .fullScreenPrimary
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.isRestorable = false
        window.showsResizeIndicator = true
        window.isMovableByWindowBackground = true
        
        // WEBVIEW
        
        let driverJs: String = {
            let path = Bundle.main.path(forResource: "driver", ofType: "js")!
            let string = try! String(contentsOfFile: path, encoding: .utf8)
            return string
        }()
        let contentController = WKUserContentController()
        let script = WKUserScript(source: driverJs, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.isElementFullscreenEnabled = false
        config.userContentController.add(self, name: "onPushState")
        config.userContentController.add(self, name: "onConsoleLog")
        config.userContentController.add(self, name: "requestFullscreen")
        
        webView = DraggableWebView(frame: window.frame, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        window.contentView?.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webView.superview!.topAnchor),
            webView.trailingAnchor.constraint(equalTo: webView.superview!.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webView.superview!.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: webView.superview!.leadingAnchor)
        ])
        
        window.makeKeyAndOrderFront(nil)
        
        let initUrl = URL(string: "https://www.viki.com" + Store.getUrl())!
        webView.load(URLRequest(url: initUrl))
        
//        NotificationCenter.default.addObserver(self, selector: #selector(updateAlwaysTopMenuItem), name: .alwaysTopNotification, object: nil)
        updateAlwaysTopMenuItem()
        
        fullscr = false
        NotificationCenter.default.addObserver(self, selector: #selector(enterFullscreen), name: NSWindow.didEnterFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(exitFullscreen), name: NSWindow.didExitFullScreenNotification, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // remove menu "show tab bar"
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func refreshBrowser(_ sender: Any) {
        webView.reload()
    }
    
    @IBOutlet weak var alwaysTopMenuItem: NSMenuItem!
    
    @IBAction func toggleAlwaysTop(_ sender: Any) {
        Store.isAlwaysTop = !Store.isAlwaysTop
    }
    
    // Update the UI
    @objc func updateAlwaysTopMenuItem() {
        alwaysTopMenuItem.state = Store.isAlwaysTop ? .on : .off
    }
    
    // enter fullscreen
    @objc func enterFullscreen() {
        webView.evaluateJavaScript("document.getElementsByClassName(\"vjs-icon-fullscreen-enter\")[0]?.setAttribute('class','vjs-icon-fullscreen-exit')") { (result, error) in
            if error == nil {
                print(result as Any)
            }
        }
        fullscr = true
    }
    
    // exit fullscreen
    @objc func exitFullscreen() {
        webView.evaluateJavaScript("document.getElementsByClassName(\"vjs-icon-fullscreen-exit\")[0]?.setAttribute('class','vjs-icon-fullscreen-enter')") { (result, error) in
            if error == nil {
                print(result as Any)
            }
        }
        fullscr = false
    }
    
    @IBAction func fixWatchError(_ sender: Any) {
        let types = Set([
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeLocalStorage
        ])
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {
            self.webView.reloadFromOrigin()
        })
    }
    
    @IBOutlet weak var hideOnHoverMenuItem: NSMenuItem!
    
    @IBAction func toggleHideOnHover(_ sender: Any) {
        let newAvoidance: Avoidance = windowController.avoidance == .off ? .ghost : .off
        windowController.avoidance = newAvoidance
        if windowController.avoidance == .off
        {
            // always phase-in in case off disabling ghost mode to avoid cases of phase-out
            window.isOpaque = true
            window.alphaValue = 1.0
            window.backgroundColor = NSColor.windowBackgroundColor
            window.hasShadow = true
            window.ignoresMouseEvents = false
            
            // when mouse already over window when ghost is de-activated then show buttons
            
            
            if(window?.contentView?.isMousePoint(window.mouseLocationOutsideOfEventStream, in: window?.contentView!.frame ?? NSRect()) == true)
            {
                window.standardWindowButton(.closeButton)?.isHidden = false
                window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                window.standardWindowButton(.zoomButton)?.isHidden = false
            }
        }
        else
        {
            // hide buttons when in ghost mode is activated
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            // when mouse already over window when ghost is activated then phase out
            if(window?.contentView?.isMousePoint(window.mouseLocationOutsideOfEventStream, in: window?.contentView!.frame ?? NSRect()) == true)
            {
                windowController.phaseOut()
            }
        }
    }
    
    func onUrlChange(path: String) {
        print("onUrlChange path=\"\(path)\"")
        // Clear aspect ratio lock when not watching a show
        if !path.hasPrefix("/videos/") {
            windowController.setAspectRatio(nil)
        }
        Store.saveUrl(path)
        if path.hasPrefix("/videos/") {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
                if (self.fullscr)
                {
                    self.webView.evaluateJavaScript("document.getElementsByClassName(\"vjs-icon-fullscreen-enter\")[0]?.setAttribute('class','vjs-icon-fullscreen-exit')") { (result, error) in
                        if error == nil {
                            print(result as Any)
                        }
                    }
                }
                else
                {
                    self.webView.evaluateJavaScript("document.getElementsByClassName(\"vjs-icon-fullscreen-exit\")[0]?.setAttribute('class','vjs-icon-fullscreen-enter')") { (result, error) in
                        if error == nil {
                            print(result as Any)
                        }
                    }
                }
            })
        }
    }
}




extension AppDelegate: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("got message from javascript: message.name=\"\(message.name)\" message.body=\(message.body)")
        // should be on url change sine more ways than pushstate
        if message.name == "onPushState", let dictionary = message.body as? [String: Any] {
            let path = (dictionary["url"] as? String) ?? "--"
            self.onUrlChange(path: path)
        } else if message.name == "onConsoleLog", let text = message.body as? String {
            print("onConsoleLog \"\(text)\"")
        } else if message.name == "requestFullscreen" {
            print("should be toggling fullscreen...")
            window.toggleFullScreen(nil)
        } else {
            print("unhandled js message: \(message.name) \(message.body)")
        }
    }
}

extension AppDelegate: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("started provisional navigation")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit")
        if let url = webView.url {
            self.onUrlChange(path: url.path)
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
    }
}

extension AppDelegate: WKUIDelegate {
    
}

func jsCompletion(obj: Any?, err: Error?) {
    if let err = err {
        print("javascript executed with error: \(err)")
    }
}



// A view that you can drag to move the underlying window around,
// but other mouse events are handled by the view.
//
// Really, it's the root view that should be draggable I think,
// but making the webview (child view) draggable makes it easy
// to disable the drag functionality by hiding the view (ghost mode) for now.
class DraggableWebView: WKWebView {
    var dragStart: Date? = nil
    
    // This alone would be sufficient except that the final mouseUp
    // after a drag gets handled by the view instead of ignored,
    // so the user will accidentally click a button if they happened
    // to start (thus end) their drag on one.
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    // Timestamp the start of any drag.
    override func mouseDragged(with event: NSEvent) {
        if dragStart == nil {
            dragStart = Date()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        print("mouse down")
        // TODO: Look into why this happens and what it means.
        if dragStart != nil {
            print("[weird] mouseDown happened while dragStart was set.")
            dragStart = nil
        }
        super.mouseDown(with: event)
    }
    
    // Figure out if the mouseUp terminated a drag or not.
    // Also consider tiny drags be clicks.
    override func mouseUp(with event: NSEvent) {
        if let dragStart = dragStart {
            let milliseconds = (Date().timeIntervalSince1970 - dragStart.timeIntervalSince1970) * 1000
            // If this delta threshold is too inaccurate, it creates
            // awful UX of failed clicks.
            print("delta:", round(milliseconds), "ms")
            self.dragStart = nil
            if milliseconds > 200 {
                return
            }
        }
        super.mouseUp(with: event)
    }
    
    override func mouseMoved(with event: NSEvent) {
        // forward mouse over events only in normal mode (disable them in ghost mode)
        if (window?.windowController as? WindowController)?.avoidance == .off
        {
            super.mouseMoved(with: event)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        // forward mouse over events only in normal mode (disable them in ghost mode)
        if (window?.windowController as? WindowController)?.avoidance == .off
        {
            super.mouseExited(with: event)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        // forward mouse over events only in normal mode (disable them in ghost mode)
        if (window?.windowController as? WindowController)?.avoidance == .off
        {
            super.mouseEntered(with: event)
        }
    }
}
