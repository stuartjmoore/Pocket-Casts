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

    @IBOutlet weak var playerDisplayToolbarItem: NSToolbarItem!
    @IBOutlet weak var playerDisplayView: NSView!

    @IBOutlet weak var showTitleToolbarTextField: NSTextField!
    @IBOutlet weak var episodeTitleToolbarTextField: NSTextField!
    @IBOutlet weak var remainingTimeToolbarTextField: NSTextField!
    @IBOutlet weak var progressBarView: NSView!

    @IBOutlet weak var progressBarViewConstraint: NSLayoutConstraint!

    private var mediaKeyTap: SPMediaKeyTap?

    var webViewController: WebViewController! {
        return window?.contentViewController as? WebViewController
    }

    override func windowDidLoad() {
        shouldCascadeWindows = false
        window?.setFrameAutosaveName("Main Window")
        windowFrameAutosaveName = "Main Window"

        super.windowDidLoad()

        (NSApplication.sharedApplication().delegate as? AppDelegate)?.window = window

        mediaKeyTap = SPMediaKeyTap(delegate: self)

        if SPMediaKeyTap.usesGlobalMediaKeyTap() {
            mediaKeyTap!.startWatchingMediaKeys()
        }

        layoutPlayerDisplay()
    }

    override func awakeFromNib() {
        progressBarView.layer?.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1).CGColor
    }

    func layoutPlayerDisplay() {
        playerDisplayToolbarItem.minSize.width = ceil(playerDisplayView.bounds.size.width) + 12
        playerDisplayToolbarItem.maxSize.width = ceil(playerDisplayView.bounds.size.width) + 12
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
        if webViewController.playerVisible {
            webViewController.hidePlayer()
            sender.state = NSOnState
        } else {
            webViewController.showPlayer()
            sender.state = NSOffState
        }

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
