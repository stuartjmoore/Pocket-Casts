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

    var mediaKeyTap: SPMediaKeyTap?

    override init() {
        let whitelist = [kMediaKeyUsingBundleIdentifiersDefaultsKey: SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()]
        NSUserDefaults.standardUserDefaults().registerDefaults(whitelist)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window.movableByWindowBackground = true
        window.titleVisibility = .Hidden
        window.styleMask |= NSFullSizeContentViewWindowMask

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gotNotification:", name: "pocketEvent", object: nil)

        webView.mainFrameURL = "https://play.pocketcasts.com/"

        mediaKeyTap = SPMediaKeyTap(delegate: self)

        if SPMediaKeyTap.usesGlobalMediaKeyTap() {
            mediaKeyTap!.startWatchingMediaKeys()
        }
    }

    func gotNotification(notification : NSNotification){
        if let u = notification.userInfo as? [String:String], action = u["action"] {
            switch action {
            case "playPause":
                println("playpause")
                webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').playPause()")

            case "skipForward":
                println("skipping forward")
                webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpForward()")

            case "skipBack":
                println("skipping back")
                webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpBack()")

            default:
                break
            }
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
                NSNotificationCenter.defaultCenter().postNotificationName("pocketEvent", object:NSApp, userInfo:["action":"playPause"])

            case Int(NX_KEYTYPE_FAST):
                NSNotificationCenter.defaultCenter().postNotificationName("pocketEvent", object: NSApp, userInfo:["action":"skipForward"])

            case Int(NX_KEYTYPE_REWIND):
                NSNotificationCenter.defaultCenter().postNotificationName("pocketEvent", object: NSApp, userInfo:["action":"skipBack"])

            default:
                break
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}
