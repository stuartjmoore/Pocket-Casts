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

    weak var window: NSWindow!

    override init() {
        let whitelist = [kMediaKeyUsingBundleIdentifiersDefaultsKey: SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()]
        UserDefaults.standard.register(defaults: whitelist)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // TODO: Figure out how to get the webView’s scrollViews underneath
        // window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
        // window.styleMask |= NSFullSizeContentViewWindowMask
        window.isMovableByWindowBackground = true
        // TODO: Set red gradient view underneath
        // window.titlebarAppearsTransparent = true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows visibleWindows: Bool) -> Bool {
        if visibleWindows {
            window.orderFront(self)
        } else {
            window.makeKeyAndOrderFront(self)
        }

        return true
    }

    // MARK: - Exit

    func applicationWillTerminate(_ aNotification: Notification) {
        return
    }

}
