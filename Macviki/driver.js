;(function() {
    'use strict'

    // INTERCEPT CONSOLE.LOG
    const oldLog = console.log
    console.log = (...args) => {
        const message = args.map((x) => String(x)).join(' ')
        window.webkit.messageHandlers.onConsoleLog.postMessage(message)
        oldLog.apply(console, args)
    }

    window.macviki = mountDriver()

    function mountDriver() {
        if (window.macviki) {
            console.log('already mounted')
            return window.macviki
        } else {
            console.log('mounting...')
        }

        let playerObserver = null

        // CSS gegen Rating-Anzeige (16, 18, etc.)
        if (!document.getElementById('macviki-age-hide')) {
            const style = document.createElement('style')
            style.id = 'macviki-age-hide'
            style.innerHTML = `
              .sc-17jko1v-0,
              .sc-akvsl4-1,
              .sc-akvsl4-0 {
                display: none !important;
              }
            `
            document.head.appendChild(style)
        }

        function handleWatchMode() {
            console.log("Activating watch mode for Viki")

            // CSS gegen Pause-Overlay
            if (!document.getElementById('macviki-hide-overlays')) {
                const style = document.createElement('style')
                style.id = 'macviki-hide-overlays'
                style.innerHTML = `
                  .vmp-pause-overlay {
                    display: none !important;
                  }
                `
                document.head.appendChild(style)
            }

            // Falls alter Observer noch läuft → stoppen
            if (playerObserver) {
                playerObserver.disconnect()
                playerObserver = null
            }

            // Neuen Observer starten (überwacht neu gespawnte Player-Elemente)
            playerObserver = new MutationObserver(mutations => {
                for (const m of mutations) {
                    for (const node of m.addedNodes) {
                        if (node.nodeType === 1) {
                            // Overlay weg
                            if (node.classList?.contains("vmp-pause-overlay")) {
                                node.style.display = "none"
                            }
                            // Fullscreen Button patchen
                            if (node.classList?.contains("vjs-icon-fullscreen-enter")) {
                                node.setAttribute(
                                    'onclick',
                                    'window.webkit.messageHandlers.requestFullscreen.postMessage(null)'
                                )
                            }
                            // Falls im DOM-Baum
                            const fs = node.querySelector?.(".vjs-icon-fullscreen-enter")
                            if (fs) {
                                fs.setAttribute(
                                    'onclick',
                                    'window.webkit.messageHandlers.requestFullscreen.postMessage(null)'
                                )
                            }
                        }
                    }
                }
            })
            playerObserver.observe(document.body, { childList: true, subtree: true })

            // Sofort initial patch
            const fsButton = document.querySelector(".vjs-icon-fullscreen-enter")
            if (fsButton) {
                fsButton.setAttribute(
                    'onclick',
                    'window.webkit.messageHandlers.requestFullscreen.postMessage(null)'
                )
            }
        }

        function handleUrlChange(path) {
            const message = { url: path }
            console.log('handleUrlChange', path)
            window.webkit.messageHandlers.onPushState.postMessage(message)

            if (path.startsWith('/videos/')) {
                handleWatchMode()
            } else {
                if (playerObserver) {
                    playerObserver.disconnect()
                    playerObserver = null
                }
            }
        }

        // --- Extra Observer für Resume-Fall ---
        const resumeObserver = new MutationObserver(mutations => {
            if (!location.pathname.startsWith('/videos/')) return
            for (const m of mutations) {
                for (const node of m.addedNodes) {
                    if (node.nodeType === 1) {
                        if (
                            node.classList?.contains('vmp-pause-overlay') ||
                            node.classList?.contains('vjs-icon-fullscreen-enter') ||
                            node.querySelector?.('.vmp-pause-overlay, .vjs-icon-fullscreen-enter')
                        ) {
                            console.log("Player resumed → reinject styles")
                            handleWatchMode()
                        }
                    }
                }
            }
        })
        resumeObserver.observe(document.body, { childList: true, subtree: true })

        // SPA Navigation abfangen
        history.onpopstate = () => handleUrlChange(location.pathname)
        window.onpopstate = () => handleUrlChange(location.pathname)

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

