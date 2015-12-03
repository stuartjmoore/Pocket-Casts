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

    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var playerSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var playerCloseButton: NSButton!

    @IBOutlet weak var episodeTitleToolbarItem: NSToolbarItem!
    @IBOutlet weak var episodeTitleToolbarTextFieldCell: NSTextFieldCell!
    @IBOutlet weak var remainingTimeToolbarTextFieldCell: NSTextFieldCell!

    var mediaKeyTap: SPMediaKeyTap?
    var updateInterfaceTimer: NSTimer!

    override init() {
        let whitelist = [kMediaKeyUsingBundleIdentifiersDefaultsKey: SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()]
        NSUserDefaults.standardUserDefaults().registerDefaults(whitelist)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window.movableByWindowBackground = true
        window.titleVisibility = .Hidden
        window.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1) /* #ff5f4f */
        window.appearance = NSAppearance(named: NSAppearanceNameAqua)
        // window.styleMask |= NSFullSizeContentViewWindowMask

        webView.mainFrameURL = "https://play.pocketcasts.com/"

        mediaKeyTap = SPMediaKeyTap(delegate: self)

        if SPMediaKeyTap.usesGlobalMediaKeyTap() {
            mediaKeyTap!.startWatchingMediaKeys()
        }

        updateInterfaceTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "updateInterfaceTimerDidFire:", userInfo: nil, repeats: true)
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
    }

    func sendJSEventForUpdatingTitle() {
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

    func sendJSEventForUpdatingRemainingTime() {
        remainingTimeToolbarTextFieldCell.title = Javascript(webView: webView).remainingTime
    }

    func sendJSEventForUpdatingPlayState() {
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

            let isPlayingString = webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').playing")

            if isPlayingString == "true" {
                sender.setLabel("❙❙", forSegment: 1)
            } else {
                sender.setLabel("▶", forSegment: 1)
            }
        } else if sender.selectedSegment == 2 {
            Javascript(webView: webView).jumpForward()
        }
    }

    @IBAction func settingsTapped(sender: NSToolbarItem) {
        Javascript(webView: webView).clickSettingsButton()
    }

    @IBAction func togglePlayerTapped(sender: NSToolbarItem) {
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

extension AppDelegate: WebFrameLoadDelegate {

    func webView(webView: WebView!, didFinishLoadForFrame: WebFrame!) {
        Javascript(webView: webView).hideToolbar()
        Javascript(webView: webView).changeFont()
    }

}

extension AppDelegate: WebPolicyDelegate {

//    func webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
//        print("decidePolicyForNavigationAction: \(actionInformation)")
//        print("decidePolicyForNavigationAction: \(request)")
//
//        if request.URL == NSURL(string: "https://play.pocketcasts.com/"), let signInURL = NSURL(string: "https://play.pocketcasts.com/users/sign_in") {
//            listener.ignore()
//
//            // TODO: Use sheet
//            let signInRequest = NSURLRequest(URL: signInURL)
//            webView.mainFrame.loadRequest(signInRequest)
//        } else {
//            listener.use()
//        }
//    }

}
