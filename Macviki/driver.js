;(function () {
  'use strict'

  const oldLog = console.log
  console.log = (...args) => {
    const msg = args.map(String).join(' ')
    try { window.webkit.messageHandlers.onConsoleLog.postMessage(msg) } catch {}
    oldLog.apply(console, args)
  }

  if (window.macviki) {
    console.log('macviki: already mounted')
    return
  }
  console.log('macviki: mounting…')

  let playerObserver = null
  const resumeAttached = new WeakSet()
  let adPhaseUntil = 0

  // ---------- helpers ----------
  function getVideoKey() {
    const path = location.pathname || ''
    return `resume_${path.replace(/[^\w-]+/g, '_')}`
  }

  function injectBaseCSS() {
    if (!document.getElementById('macviki-base-style')) {
      const st = document.createElement('style')
      st.id = 'macviki-base-style'
      st.textContent = `
        .sc-17jko1v-0, .sc-akvsl4-1, .sc-akvsl4-0 {display:none!important;}
        .vmp-pause-overlay {display:none!important;}
      `
      document.head.appendChild(st)
    }
  }

  function patchFullscreen(node) {
    try {
      const fs = node?.classList?.contains('vjs-icon-fullscreen-enter')
        ? node
        : node?.querySelector?.('.vjs-icon-fullscreen-enter')
      if (fs && !fs.dataset.macviki) {
        fs.dataset.macviki = '1'
        fs.setAttribute(
          'onclick',
          'window.webkit.messageHandlers.requestFullscreen.postMessage(null)'
        )
        console.log('macviki: fullscreen button patched')
      }
    } catch {}
  }

  // ---------- ad detection ----------
  function interceptConsoleForAds() {
    const nativeLog = console.log
    console.log = (...args) => {
      const msg = args.join(' ')
      if (msg.includes('VIDEOJS: adserror (Preroll)')) {
        adPhaseUntil = Date.now() + 10000 // 10 Sekunden aktiv
        nativeLog('macviki: adPhase triggered for 10s')
      }
      try { window.webkit.messageHandlers.onConsoleLog.postMessage(msg) } catch {}
      nativeLog.apply(console, args)
    }
  }
  interceptConsoleForAds()

  // ---------- video hooks ----------
  function attachVideoHooks(video) {
    if (!video || resumeAttached.has(video)) return
    resumeAttached.add(video)

    const key = getVideoKey()
    console.log('macviki: attach resume hook for', key)

    let resumeTime = 0
    try { resumeTime = parseFloat(localStorage.getItem(key) || '0') } catch {}
    console.log('macviki: stored resumeTime =', resumeTime)

    let enforced = false

    function applyResume(force = false) {
      if (!resumeTime || video.duration < resumeTime + 2) return
      if (force || Math.abs(video.currentTime - resumeTime) > 1) {
        try {
          video.currentTime = resumeTime
          console.log('macviki: resume applied currentTime=', video.currentTime)
          enforced = true
        } catch (e) {
          console.log('macviki: resume failed', e)
        }
      }
    }

    video.addEventListener('loadedmetadata', () => {
      console.log('macviki: loadedmetadata', video.duration, video.currentSrc)
      if (video.duration < 30) {
        console.log('macviki: detected intro roll → skipping')
        video.currentTime = video.duration || 5
      } else applyResume(true)
    })

    // falls Viki nachträglich seekt → nur bei aktiver adPhase reagieren
    video.addEventListener('seeked', () => {
      if (Date.now() < adPhaseUntil && video.currentTime < resumeTime - 1) {
        console.log('macviki: adPhase rewind detected → restoring resume')
        applyResume(true)
      }
    })

    // safety-timer: nur in adPhase aktiv
    const watchdog = setInterval(() => {
      if (!document.body.contains(video)) return clearInterval(watchdog)
      if (Date.now() < adPhaseUntil && video.currentTime < resumeTime - 2) {
        console.log('macviki: adPhase watchdog restoring resume')
        applyResume(true)
      }
    }, 2000)

    // Fortschritt speichern (throttled)
    let lastSave = 0
    video.addEventListener('timeupdate', () => {
      const now = Date.now()
      if (now - lastSave > 5000) {
        lastSave = now
        try {
          const pos = video.currentTime.toFixed(1)
          localStorage.setItem(key, pos)
          console.log(`macviki: progress saved [${key}]`, pos)
        } catch (e) {}
      }
    })
  }

  // ---------- watch mode ----------
  function handleWatchMode() {
    console.log('macviki: Activating watch mode')
    injectBaseCSS()

    if (playerObserver) playerObserver.disconnect()
    playerObserver = new MutationObserver((mutations) => {
      for (const m of mutations) {
        for (const node of m.addedNodes) {
          if (node.nodeType !== 1) continue
          patchFullscreen(node)
          const v = node.tagName === 'VIDEO' ? node : node.querySelector?.('video')
          if (v) attachVideoHooks(v)
        }
      }
    })
    playerObserver.observe(document.body, { childList: true, subtree: true })

    patchFullscreen(document)
    document.querySelectorAll('video').forEach((v) => attachVideoHooks(v))
  }

  // ---------- navigation ----------
  function handleUrlChange(path) {
    console.log('macviki: handleUrlChange', path)
    try { window.webkit.messageHandlers.onPushState.postMessage({ url: path }) } catch {}
    if (path.startsWith('/videos/')) handleWatchMode()
    else if (playerObserver) {
      playerObserver.disconnect()
      playerObserver = null
    }
  }

  history.onpopstate = () => handleUrlChange(location.pathname)
  window.onpopstate = () => handleUrlChange(location.pathname)
  const origPush = history.pushState
  history.pushState = function (s, t, url) {
    const res = origPush.apply(this, arguments)
    handleUrlChange(url)
    return res
  }

  // ---------- resume observer ----------
  const resumeObserver = new MutationObserver((muts) => {
    if (!location.pathname.startsWith('/videos/')) return
    for (const m of muts)
      for (const n of m.addedNodes)
        if (n.nodeType === 1 && n.querySelector?.('video')) {
          console.log('macviki: resume observer found video')
          handleWatchMode()
        }
  })
  resumeObserver.observe(document.body, { childList: true, subtree: true })

  injectBaseCSS()
  console.log('macviki: ready')
  window.macviki = { resumeAttached }
})()

