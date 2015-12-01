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

    enum KeyAction {
        case PlayPause, SkipForward, SkipBack
    }

    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var remainingTimeToolbarItem: NSTextFieldCell!

    var mediaKeyTap: SPMediaKeyTap?
    var updateInterfaceTimer: NSTimer!

    override init() {
        let whitelist = [kMediaKeyUsingBundleIdentifiersDefaultsKey: SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()]
        NSUserDefaults.standardUserDefaults().registerDefaults(whitelist)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window.movableByWindowBackground = true
        window.titleVisibility = .Hidden
        window.styleMask |= NSFullSizeContentViewWindowMask

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

    func updateInterfaceTimerDidFire(timer: NSTimer) {
        sendJSEventForRemainingTime()
    }

    // MARK: - Javascript

    /*
        angular.element(document).injector().get('mediaPlayer')…
            closePlayer() (stops playback?)
            episode.title
            loaded
            seekTo(x)
    */

    func sendJSEventForRemainingTime() {
        let x = "document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText"
        let remainingTimeString = webView.stringByEvaluatingJavaScriptFromString(x)
        remainingTimeToolbarItem.title = remainingTimeString
    }

    func sendJSEventForHidingToolbar() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('header').style.top = '-70px';") /* header height */
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingTop = 0;")
    }

    func sendJSEventForChangingFont() {
        webView.stringByEvaluatingJavaScriptFromString("document.body.style.fontFamily = '-apple-system';")
    }

    func sendJSEventForSearchChange(text: String) {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('search_input_value').value = '\(text)';")
        // angular.element("#search_input_value").scope().inputChangeHandler("alison")
        //
        // TODO: fire onChange()
    }

    func sendJSEventForSettingsTap() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('dropdown-toggle')[0].firstChild.click();")
    }

    func sendJSEventForHidingPlayer() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingBottom = 0;")
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('audio_player').style.display = 'none';")
    }

    func sendJSEventForShowingPlayer() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingBottom = '66px';")
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('audio_player').style.display = 'block';")
    }

    func sendJSEventForAction(action: KeyAction) {
        switch action {
        case .PlayPause:
            print("playpause")
            webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').playPause()")

        case .SkipForward:
            print("skipping forward")
            webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpForward()")

        case .SkipBack:
            print("skipping back")
            webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpBack()")
        }
    }

    // MARK: - Menu Bar

    @IBAction func playPauseMenuItemTapped(sender: NSMenuItem) {
        sendJSEventForAction(.PlayPause)
    }

    @IBAction func skipForwardMenuItemTapped(sender: NSMenuItem) {
        sendJSEventForAction(.SkipForward)
    }

    @IBAction func skipBackMenuItemTapped(sender: NSMenuItem) {
        sendJSEventForAction(.SkipBack)
    }

    // MARK: Toolbar

    @IBAction func playerSegmentTapped(sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            sendJSEventForAction(.SkipBack)
        } else if sender.selectedSegment == 1 {
            sendJSEventForAction(.PlayPause)

            let isPlayingString = webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').playing")

            if isPlayingString == "true" {
                sender.setLabel("❙❙", forSegment: 1)
            } else {
                sender.setLabel("▶", forSegment: 1)
            }
        } else if sender.selectedSegment == 2 {
            sendJSEventForAction(.SkipForward)
        }

        sendJSEventForRemainingTime()
    }

    @IBAction func settingsTapped(sender: NSToolbarItem) {
        sendJSEventForSettingsTap()
    }

    @IBAction func togglePlayerTapped(sender: NSToolbarItem) {
        if sender.tag == 0 {
            sendJSEventForHidingPlayer()
            sender.tag = 1
        } else {
            sendJSEventForShowingPlayer()
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
                sendJSEventForAction(.PlayPause)

            case Int(NX_KEYTYPE_FAST):
                sendJSEventForAction(.SkipForward)

            case Int(NX_KEYTYPE_REWIND):
                sendJSEventForAction(.SkipBack)

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
        sendJSEventForHidingToolbar()
        sendJSEventForChangingFont()
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
