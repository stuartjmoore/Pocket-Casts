//
//  MainWindowController.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 12/8/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa
import WebKit

class MainWindowController: NSWindowController {

    @IBOutlet weak var playerSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var playerCloseButton: NSButton!

    @IBOutlet weak var episodeTitleToolbarItem: NSToolbarItem!
    @IBOutlet weak var episodeTitleToolbarTextFieldCell: NSTextFieldCell!
    @IBOutlet weak var remainingTimeToolbarTextFieldCell: NSTextFieldCell!

    private var mediaKeyTap: SPMediaKeyTap?

    var webViewController: WebViewController! {
        return window?.contentViewController as? WebViewController
    }

    override func windowDidLoad() {
        shouldCascadeWindows = false
        window?.setFrameAutosaveName("MainWindow")

        super.windowDidLoad()

        (NSApplication.sharedApplication().delegate as? AppDelegate)?.window = window

        mediaKeyTap = SPMediaKeyTap(delegate: self)

        if SPMediaKeyTap.usesGlobalMediaKeyTap() {
            mediaKeyTap!.startWatchingMediaKeys()
        }
    }

    // MARK: Toolbar

    @IBAction func playerSegmentTapped(sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            webViewController.jumpBack()
        } else if sender.selectedSegment == 1 {
            webViewController.playPause()
        } else if sender.selectedSegment == 2 {
            webViewController.jumpForward()
        }
    }

    @IBAction func settingsTapped(sender: NSButton) {
        webViewController.clickSettingsButton()
    }

    @IBAction func togglePlayerTapped(sender: NSButton) {
        if sender.state == NSOffState {
            webViewController.hidePlayer()
        } else {
            webViewController.showPlayer()
        }

        sender.state = (sender.state == NSOnState) ? NSOffState : NSOnState
        sender.setNextState()
    }

    // MARK: Media Keys

    override func mediaKeyTap(mediaKeyTap: SPMediaKeyTap?, receivedMediaKeyEvent event: NSEvent) {
        let keyCode = Int((event.data1 & 0xFFFF0000) >> 16)
        let keyFlags = (event.data1 & 0x0000FFFF)
        let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA

        if keyIsPressed {
            switch keyCode {
            case Int(NX_KEYTYPE_PLAY):
                webViewController.playPause()

            case Int(NX_KEYTYPE_FAST):
                webViewController.jumpForward()

            case Int(NX_KEYTYPE_REWIND):
                webViewController.jumpBack()

            default:
                break
            }
        }
    }

}
