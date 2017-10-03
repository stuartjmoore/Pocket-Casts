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
    @IBOutlet weak var playerDisplayView: NSStackView!

    @IBOutlet weak var showTitleToolbarTextField: NSTextField!
    @IBOutlet weak var episodeTitleToolbarTextField: NSTextField!
    @IBOutlet weak var remainingTimeToolbarTextField: NSTextField!
    @IBOutlet weak var progressSlider: NSSlider!

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

//        progressBarView.layer?.masksToBounds = true
//        progressBarView.layer?.cornerRadius = 1
//        progressBarView.layer?.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1).cgColor
    }

    func layoutPlayerDisplay() {
        let showTitleWidth = showTitleToolbarTextField.intrinsicContentSize.width
        let episodeTitleWidth = episodeTitleToolbarTextField.intrinsicContentSize.width
        let remainingTimeWidth = remainingTimeToolbarTextField.intrinsicContentSize.width
        let marginWidth = playerDisplayView.spacing
        let playerDisplayWidth = ceil(showTitleWidth + marginWidth + episodeTitleWidth + marginWidth + remainingTimeWidth)

        playerDisplayToolbarItem.minSize.width = playerDisplayWidth
        playerDisplayToolbarItem.maxSize.width = playerDisplayWidth
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
            progressSlider.floatValue = progressPercentage ?? 0
        } get {
            return Float(progressSlider.floatValue)
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

    @IBAction func progressSliderMoved(_ sender: NSSlider) {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2

        let timeInterval = webViewController.timeInterval(atPercentage: sender.doubleValue)

        guard !timeInterval.isNaN else {
            return
        }

        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))

        let hoursString = formatter.string(from: NSNumber(integerLiteral: hours)) ?? ""
        let minutesString = formatter.string(from: NSNumber(integerLiteral: minutes)) ?? ""
        let secondsString = formatter.string(from: NSNumber(integerLiteral: seconds)) ?? ""

        remainingTimeToolbarTextField.stringValue = "\(hoursString):\(minutesString):\(secondsString)"

        if let event = NSApplication.shared.currentEvent, event.type == .leftMouseUp {
            webViewController.jump(toPercentage: sender.doubleValue)
        }

        layoutPlayerDisplay()
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
