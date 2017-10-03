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

    @IBOutlet weak var playerDisplayToolbarItem: NSToolbarItem!
    @IBOutlet weak var playerDisplayView: NSView!

    @IBOutlet weak var showTitleToolbarTextField: NSTextField!
    @IBOutlet weak var episodeTitleToolbarTextField: NSTextField!
    @IBOutlet weak var remainingTimeToolbarTextField: NSTextField!
    @IBOutlet weak var progressBarView: NSView!

    @IBOutlet weak var progressBarViewConstraint: NSLayoutConstraint!

    fileprivate var mediaKeyTap: SPMediaKeyTap?

    var webViewController: WebViewController! {
        return window?.contentViewController as? WebViewController
    }

    override func windowDidLoad() {
        shouldCascadeWindows = false
        window?.titleVisibility = .hidden
        window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "Main Window"))
        windowFrameAutosaveName = NSWindow.FrameAutosaveName(rawValue: "Main Window")

        super.windowDidLoad()

        (NSApplication.shared.delegate as? AppDelegate)?.window = window

        mediaKeyTap = SPMediaKeyTap(delegate: self)

        if SPMediaKeyTap.usesGlobalMediaKeyTap() {
            mediaKeyTap!.startWatchingMediaKeys()
        }

        layoutPlayerDisplay()
    }

    override func awakeFromNib() {
        remainingTimeToolbarTextField.font = remainingTimeToolbarTextField.font?.fontByAddingAttribute(
            [kNumberSpacingType: kMonospacedNumbersSelector]
        )

        progressBarView.layer?.masksToBounds = true
        progressBarView.layer?.cornerRadius = 6
        progressBarView.layer?.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1).cgColor
    }

    func layoutPlayerDisplay() {
        playerDisplayToolbarItem.minSize.width = ceil(playerDisplayView.bounds.size.width) + 12
        playerDisplayToolbarItem.maxSize.width = ceil(playerDisplayView.bounds.size.width) + 12
    }

    // MARK: - Set Items

    var showTitle: String? {
        set(showTitle) {
            showTitleToolbarTextField.stringValue = showTitle ?? ""
            layoutPlayerDisplay()
        } get {
            return showTitleToolbarTextField.stringValue
        }
    }

    var episodeTitle: String? {
        set(episodeTitle) {
            episodeTitleToolbarTextField.stringValue = episodeTitle ?? ""
            layoutPlayerDisplay()
        } get {
            return episodeTitleToolbarTextField.stringValue
        }
    }

    var remainingTimeText: String? {
        set(remainingTimeText) {
            remainingTimeToolbarTextField.stringValue = remainingTimeText ?? ""
            layoutPlayerDisplay()
        } get {
            return remainingTimeToolbarTextField.stringValue
        }
    }

    var progressPercentage: Float? {
        set(progressPercentage) {
            progressBarViewConstraint.constant = playerDisplayView.frame.width * CGFloat(progressPercentage ?? 0)
        } get {
            return Float(progressBarViewConstraint.constant)
        }
    }

    var playerState: PlayerState = .stopped {
        didSet {
            switch playerState {
            case .stopped, .buffering:
                playerSegmentedControl.setLabel("▶❙❙", forSegment: 1)
                playerSegmentedControl.isEnabled = false

            case .playing:
                playerSegmentedControl.setLabel("❙❙", forSegment: 1)
                playerSegmentedControl.isEnabled = true

            case .paused:
                playerSegmentedControl.setLabel("▶", forSegment: 1)
                playerSegmentedControl.isEnabled = true
            }
        }
    }

    // MARK: - Toolbar

    @IBAction func upNextTapped(_ sender: NSButton) {
        webViewController.showUpNext()
    }

    @IBAction func playerSegmentTapped(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            webViewController.jumpBack()
        } else if sender.selectedSegment == 1 {
            webViewController.playPause()
        } else if sender.selectedSegment == 2 {
            webViewController.jumpForward()
        }
    }

    // MARK: Media Keys

    override func mediaKeyTap(_ mediaKeyTap: SPMediaKeyTap?, receivedMediaKeyEvent event: NSEvent) {
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

extension NSFont {
    func fontByAddingAttribute(_ input: [Int: Int]) -> NSFont? {
        let attribute = input.map({ [NSFontDescriptor.FeatureKey.typeIdentifier: $0, NSFontDescriptor.FeatureKey.selectorIdentifier: $1] })
        let attributes = [NSFontDescriptor.AttributeName.featureSettings: attribute]
        let attributedFontDescriptor = fontDescriptor.addingAttributes(attributes)
        return NSFont(descriptor: attributedFontDescriptor, size: 0)
    }
}
