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

    var mediaKeyTap: SPMediaKeyTap?

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
    }

    func sendJSEventForHidingToolbar() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('header').style.visibility = 'hidden';")
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingTop = 0;")
    }

    func sendJSEventForAction(action: KeyAction) {
        switch action {
        case .PlayPause:
            println("playpause")
            webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').playPause()")

        case .SkipForward:
            println("skipping forward")
            webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpForward()")

        case .SkipBack:
            println("skipping back")
            webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpBack()")

        default:
            break
        }
    }

    override func mediaKeyTap(mediaKeyTap: SPMediaKeyTap?, receivedMediaKeyEvent event: NSEvent) {
        let keyCode = Int((event.data1 & 0xFFFF0000) >> 16)
        let keyFlags = (event.data1 & 0x0000FFFF)
        let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA
        let keyRepeat = (keyFlags & 0x1)

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

    func applicationWillTerminate(aNotification: NSNotification) {
        return
    }

}

extension AppDelegate {

    override func webView(webView: WebView!, didFinishLoadForFrame: WebFrame!) {
        sendJSEventForHidingToolbar()
    }

}
