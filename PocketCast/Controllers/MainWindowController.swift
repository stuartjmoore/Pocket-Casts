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
    private var updateInterfaceTimer: NSTimer!

    var mainViewController: MainViewController! {
        return window?.contentViewController as? MainViewController
    }

    var webView: WKWebView! {
        return mainViewController.webView
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

        updateInterfaceTimer = NSTimer.scheduledTimerWithTimeInterval(0.75,
            target: self,
            selector: "updateInterfaceTimerDidFire:",
            userInfo: nil,
            repeats: true
        )
    }

    // MARK: - Timers

    func updateInterfaceTimerDidFire(timer: NSTimer) {
        sendJSEventForUpdatingTitle()
        sendJSEventForUpdatingRemainingTime()
        sendJSEventForUpdatingPlayState()
        sendJSEventForUpdatingProgressBar()
    }

    private func sendJSEventForUpdatingTitle() {
        guard let showTitle = Javascript(webView: webView).showTitle,
              let episodeTitle = Javascript(webView: webView).episodeTitle else {
            return episodeTitleToolbarTextFieldCell.title = ""
        }

        episodeTitleToolbarTextFieldCell.title = showTitle + " – " + episodeTitle

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
        guard let remainingTime = Javascript(webView: webView).remainingTime else {
            return remainingTimeToolbarTextFieldCell.title = ""
        }

        remainingTimeToolbarTextFieldCell.title = remainingTime
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
        mainViewController.updateProgressBarView(percentage)
    }

    // MARK: Toolbar

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
        if playerCloseButton.state == NSOffState {
            Javascript(webView: webView).hidePlayer()
        } else {
            Javascript(webView: webView).showPlayer()
        }

        playerCloseButton.state = (playerCloseButton.state == NSOnState) ? NSOffState : NSOnState
        playerCloseButton.setNextState()
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

}
