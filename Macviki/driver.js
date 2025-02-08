;(function() {
    'use strict'

    // INTERCEPT CONSOLE.LOG

    const oldLog = console.log
    console.log = (...args) => {
        const message = args.map((x) => String(x)).join(' ')
        window.webkit.messageHandlers.onConsoleLog.postMessage(message)
        oldLog.apply(console, args)
    }

    window.macflix = mountDriver()

    function mountDriver() {
        if (window.macflix) {
            console.log('already mounted')
            return window.macflix
        } else {
            console.log('mounting...')
        }
        
        ////////////////////////////////////////////////////////////

        // workaround: try install once per each sec (was not working on url change event?)
        setInterval(function() {
            // we only do changes once we on the videos page
            if (location.pathname.startsWith('/videos/')) {
                // REMOVE ANNOYING VIDEO PAUSE OVERLAY
                document.getElementsByClassName("vmp-pause-overlay")[0]?.remove();
                
                // DETECT ONCLICK ON FULLSCREEN BUTTON
                document.getElementsByClassName("vjs-icon-fullscreen-enter")[0]?.setAttribute('onclick','window.webkit.messageHandlers.requestFullscreen.postMessage(null)')
            }
        }, 1000);
        
        ////////////////////////////////////////////////////////////
        
        // some helper query functions (not used at the moment)

        const qs = (...args) => document.querySelector(...args)
        const qsa = (...args) => document.querySelectorAll(...args)

        ////////////////////////////////////////////////////////////

        // DETECT URL CHANGE
        
        function handleUrlChange(path) {
            const message = { url: path }
            console.log('handleUrlChange ', path)
            window.webkit.messageHandlers.onPushState.postMessage(message)
        }

        const pushState = history.pushState
        history.pushState = (...args) => {
            console.log('history.pushState')
            const [state, title, url] = args
            if (typeof history.onpushstate === 'function') {
                history.onpushstate(...args)
            }
            handleUrlChange(url)
            return pushState.apply(history, args)
        }
    }
})()
