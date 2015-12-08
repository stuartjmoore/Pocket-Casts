//
//  AppDelegate.swift
//  PocketCast
//
//  Created by Morten Just Petersen on 4/14/15.
//  Copyright (c) 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa
import WebKit

@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressLayoutConstraint: NSLayoutConstraint!

    @IBOutlet weak var playerSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var playerCloseButton: NSButton!

    @IBOutlet weak var episodeTitleToolbarItem: NSToolbarItem!
    @IBOutlet weak var episodeTitleToolbarTextFieldCell: NSTextFieldCell!
    @IBOutlet weak var remainingTimeToolbarTextFieldCell: NSTextFieldCell!

    var webView: WKWebView!
    var loginSheet: NSPanel!

    var mediaKeyTap: SPMediaKeyTap?
    var updateInterfaceTimer: NSTimer!

    override init() {
        let whitelist = [kMediaKeyUsingBundleIdentifiersDefaultsKey: SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()]
        NSUserDefaults.standardUserDefaults().registerDefaults(whitelist)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // TODO: Figure out how to get the webView’s scrollViews underneath
        // window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
        // window.styleMask |= NSFullSizeContentViewWindowMask
        window.movableByWindowBackground = true
        // TODO: Set red gradient view underneath
        // window.titlebarAppearsTransparent = true
        window.titleVisibility = .Hidden

        webView = WKWebView(frame: window.contentView?.bounds ?? .zero)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(webView, positioned: .Below, relativeTo: nil)

        /* window.frame.height + window.contentLayoutRect.maxY */
        window.contentLayoutGuide?.topAnchor.constraintEqualToAnchor(webView.topAnchor).active = true
        window.contentView?.leadingAnchor.constraintEqualToAnchor(webView.leadingAnchor).active = true
        window.contentView?.bottomAnchor.constraintEqualToAnchor(webView.bottomAnchor).active = true
        window.contentView?.trailingAnchor.constraintEqualToAnchor(webView.trailingAnchor).active = true

        if let pocketCastsURL = NSURL(string: "https://play.pocketcasts.com/web") {
            let pocketCastsRequest = NSURLRequest(URL: pocketCastsURL)
            webView.loadRequest(pocketCastsRequest)
        } else {
            fatalError("Unable to create Pocket Casts URL.")
        }

        mediaKeyTap = SPMediaKeyTap(delegate: self)

        if SPMediaKeyTap.usesGlobalMediaKeyTap() {
            mediaKeyTap!.startWatchingMediaKeys()
        }

        updateInterfaceTimer = NSTimer.scheduledTimerWithTimeInterval(0.75, target: self, selector: "updateInterfaceTimerDidFire:", userInfo: nil, repeats: true)
    }

    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows visibleWindows: Bool) -> Bool {
        if visibleWindows {
            window.orderFront(self)
        } else {
            window.makeKeyAndOrderFront(self)
        }

        return true
    }

    // MARK: - Timers

    func updateInterfaceTimerDidFire(timer: NSTimer) {
        sendJSEventForUpdatingTitle()
        sendJSEventForUpdatingRemainingTime()
        sendJSEventForUpdatingPlayState()
        sendJSEventForUpdatingProgressBar()
    }

    private func sendJSEventForUpdatingTitle() {
        episodeTitleToolbarTextFieldCell.title = Javascript(webView: webView).episodeTitle

        if episodeTitleToolbarTextFieldCell.attributedStringValue.length > 0 {
            let rect = episodeTitleToolbarTextFieldCell.attributedStringValue.boundingRectWithSize(
                NSSize(width: CGFloat.max, height: CGFloat.max),
                options: [.UsesLineFragmentOrigin, .UsesFontLeading]
            )

            episodeTitleToolbarItem.minSize.width = ceil(rect.size.width) + 16
            episodeTitleToolbarItem.maxSize.width = ceil(rect.size.width) + 16
        }
    }

    private func sendJSEventForUpdatingRemainingTime() {
        remainingTimeToolbarTextFieldCell.title = Javascript(webView: webView).remainingTime
    }

    private func sendJSEventForUpdatingPlayState() {
        if Javascript(webView: webView).isPlayerOpen {
            playerSegmentedControl.enabled = true
            playerCloseButton.enabled = true

            if Javascript(webView: webView).isPlaying {
                playerSegmentedControl.setLabel("❙❙", forSegment: 1)
            } else {
                playerSegmentedControl.setLabel("▶", forSegment: 1)
            }
        } else {
            playerSegmentedControl.enabled = false
            playerCloseButton.enabled = false
            playerSegmentedControl.setLabel("▶❙❙", forSegment: 1)
        }
    }

    private func sendJSEventForUpdatingProgressBar() {
        let percentage = Javascript(webView: webView).currentPercentage
        progressLayoutConstraint.constant = window.contentLayoutRect.width * CGFloat(percentage)
    }

    // MARK: - Menu Bar

    @IBAction func playPauseMenuItemTapped(sender: NSMenuItem) {
        Javascript(webView: webView).playPause()
    }

    @IBAction func skipForwardMenuItemTapped(sender: NSMenuItem) {
        Javascript(webView: webView).jumpForward()
    }

    @IBAction func skipBackMenuItemTapped(sender: NSMenuItem) {
        Javascript(webView: webView).jumpBack()
    }

    // MARK: Toolbar

    /*
        angular.element(document).injector().get('mediaPlayer')…
            seekTo(x)
     */

    @IBAction func playerSegmentTapped(sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            Javascript(webView: webView).jumpBack()
        } else if sender.selectedSegment == 1 {
            Javascript(webView: webView).playPause()

            if Javascript(webView: webView).isPlaying {
                sender.setLabel("❙❙", forSegment: 1)
            } else {
                sender.setLabel("▶", forSegment: 1)
            }
        } else if sender.selectedSegment == 2 {
            Javascript(webView: webView).jumpForward()
        }
    }

    @IBAction func settingsTapped(sender: NSButton) {
        Javascript(webView: webView).clickSettingsButton()
    }

    @IBAction func togglePlayerTapped(sender: NSButton) {
        if sender.tag == 0 {
            Javascript(webView: webView).hidePlayer()
            sender.tag = 1
        } else {
            Javascript(webView: webView).showPlayer()
            sender.tag = 0
        }
    }

    // MARK: Media Keys

    override func mediaKeyTap(mediaKeyTap: SPMediaKeyTap?, receivedMediaKeyEvent event: NSEvent) {
        let keyCode = Int((event.data1 & 0xFFFF0000) >> 16)
        let keyFlags = (event.data1 & 0x0000FFFF)
        let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA

        if keyIsPressed {
            switch keyCode {
            case Int(NX_KEYTYPE_PLAY):
                Javascript(webView: webView).playPause()

            case Int(NX_KEYTYPE_FAST):
                Javascript(webView: webView).jumpForward()

            case Int(NX_KEYTYPE_REWIND):
                Javascript(webView: webView).jumpBack()

            default:
                break
            }
        }
    }

    // MARK: - Exit

    func applicationWillTerminate(aNotification: NSNotification) {
        return
    }

}

extension AppDelegate: WKNavigationDelegate {

    func webView(webView: WKWebView, didFinishNavigation: WKNavigation!) {
        // TODO: Move to window or view controller
        progressView.layer?.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1).CGColor

        Javascript(webView: webView).hideToolbar()
        Javascript(webView: webView).changeFont()
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if webView === self.webView && navigationAction.request.URL?.path == "/users/sign_in" {
            loginSheet = NSPanel()

            if let rect = window.contentView?.bounds {
                loginSheet.setContentSize(rect.insetBy(dx: 44, dy: 22).size)
            }

            let loginWebView = WKWebView(frame: loginSheet.contentView?.bounds ?? .zero)
            loginWebView.navigationDelegate = self
            loginWebView.translatesAutoresizingMaskIntoConstraints = false
            loginSheet.contentView?.addSubview(loginWebView)

            loginSheet.contentView?.topAnchor.constraintEqualToAnchor(loginWebView.topAnchor).active = true
            loginSheet.contentView?.leadingAnchor.constraintEqualToAnchor(loginWebView.leadingAnchor).active = true
            loginSheet.contentView?.bottomAnchor.constraintEqualToAnchor(loginWebView.bottomAnchor).active = true
            loginSheet.contentView?.trailingAnchor.constraintEqualToAnchor(loginWebView.trailingAnchor).active = true

            loginWebView.loadRequest(navigationAction.request)
            window.beginSheet(loginSheet, completionHandler: nil)
            decisionHandler(.Cancel)
        } else if webView !== self.webView && navigationAction.request.URL?.path == "/web" {
            self.webView.loadRequest(navigationAction.request)
            window.endSheet(loginSheet)
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }

}
