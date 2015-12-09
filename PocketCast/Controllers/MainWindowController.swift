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
        guard let showTitle = mainViewController.showTitle,
              let episodeTitle = mainViewController.episodeTitle else {
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
        guard let remainingTime = mainViewController.remainingTime else {
            return remainingTimeToolbarTextFieldCell.title = ""
        }

        remainingTimeToolbarTextFieldCell.title = remainingTime
    }

    private func sendJSEventForUpdatingPlayState() {
        if mainViewController.isPlayerOpen {
            playerSegmentedControl.enabled = true
            playerCloseButton.enabled = true

            if mainViewController.isPlaying {
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
        let percentage = mainViewController.currentPercentage
        mainViewController.updateProgressBarView(percentage)
    }

    // MARK: Toolbar

    @IBAction func playerSegmentTapped(sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            mainViewController.jumpBack()
        } else if sender.selectedSegment == 1 {
            mainViewController.playPause()

            if mainViewController.isPlaying {
                sender.setLabel("❙❙", forSegment: 1)
            } else {
                sender.setLabel("▶", forSegment: 1)
            }
        } else if sender.selectedSegment == 2 {
            mainViewController.jumpForward()
        }
    }

    @IBAction func settingsTapped(sender: NSButton) {
        mainViewController.clickSettingsButton()
    }

    @IBAction func togglePlayerTapped(sender: NSButton) {
        if sender.state == NSOffState {
            mainViewController.hidePlayer()
        } else {
            mainViewController.showPlayer()
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
                mainViewController.playPause()

            case Int(NX_KEYTYPE_FAST):
                mainViewController.jumpForward()

            case Int(NX_KEYTYPE_REWIND):
                mainViewController.jumpBack()

            default:
                break
            }
        }
    }

}
