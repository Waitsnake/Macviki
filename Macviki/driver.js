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

        // workaround: try once per each secound
        setInterval(function() {
            // remove the annoying viki pause overlay
            document.getElementsByClassName("vmp-pause-overlay")[0]?.remove();
            
            // add a onclick function to HTML5 fullscreen button that transmit event to swift code
            document.getElementsByClassName("vjs-icon-fullscreen-enter")[0]?.setAttribute('onclick','window.webkit.messageHandlers.requestFullscreen.postMessage(null)')
        }, 1000);
        
        // Makes necessary changes to the DOM and then returns functions that depend on those mutations
        // to drive Netflix.

        const qs = (...args) => document.querySelector(...args)
        const qsa = (...args) => document.querySelectorAll(...args)


        // Walks entirety of an html node's downstream tree and
        // returns Set of <video> nodes it finds.
        //
        // root is node | null
        // found is Set of matching nodes
        function crawlNode(root, found = new Set()) {
            const predicate = (node) => node && node.tagName === 'VIDEO'
            if (!root || !root.childNodes) {
                return found
            }
            if (predicate(root)) {
                found.add(root)
            }
            return Array.from(root.childNodes).reduce((acc, node) => {
                if (predicate(node)) {
                    return crawlNode(node, new Set([...acc, node]))
                } else {
                    return crawlNode(node, acc)
                }
            }, found)
        }

        // This version takes an array of nodes
        function crawlNodes(roots) {
            return Array.from(roots).reduce((acc, node) => crawlNode(node, acc), new Set())
        }

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
