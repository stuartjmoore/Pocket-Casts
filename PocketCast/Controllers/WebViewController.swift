//
//  WebViewController.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 12/8/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController {

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressLayoutConstraint: NSLayoutConstraint!

    private var javascript: Javascript!
    private var loginSheet: NSPanel!
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        progressView.wantsLayer = true

        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView, positioned: .Below, relativeTo: progressView)

        view.topAnchor.constraintEqualToAnchor(webView.topAnchor).active = true
        view.leadingAnchor.constraintEqualToAnchor(webView.leadingAnchor).active = true
        view.bottomAnchor.constraintEqualToAnchor(webView.bottomAnchor).active = true
        view.trailingAnchor.constraintEqualToAnchor(webView.trailingAnchor).active = true

        if let pocketCastsURL = NSURL(string: "https://play.pocketcasts.com/web") {
            let pocketCastsRequest = NSURLRequest(URL: pocketCastsURL)
            webView.loadRequest(pocketCastsRequest)
        } else {
            fatalError("Unable to create Pocket Casts URL.")
        }

        javascript = Javascript(webView: webView)
        javascript.delegate = self
    }

    override func awakeFromNib() {
        progressView.layer?.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1).CGColor
    }

    func updateProgressBarView(percentage: Float) {
        progressLayoutConstraint.constant = view.frame.width * CGFloat(percentage)
    }

    func loadRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }

    // MARK: - Javascript

    var isPlaying: Bool {
        return javascript.isPlaying ?? false
    }

    // MARK: Actions

    func jumpBack() {
        javascript.jumpBack()
    }

    func playPause() {
        javascript.playPause()
    }

    func jumpForward() {
        javascript.jumpForward()
    }

    func clickSettingsButton() {
        javascript.clickSettingsButton()
    }

    func hidePlayer() {
        javascript.hidePlayer()
    }

    func showPlayer() {
        javascript.showPlayer()
    }

}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(webView: WKWebView, didFinishNavigation: WKNavigation!) {
        javascript.hideToolbar()
        javascript.changeFont()
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if webView === self.webView && navigationAction.request.URL?.path == "/users/sign_in" {
            performSegueWithIdentifier("LoginSheetIdentifier", sender: navigationAction.request)
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LoginSheetIdentifier",
        let loginViewController = segue.destinationController as? LoginViewController, request = sender as? NSURLRequest {
            loginViewController.request = request
        }
    }

}

// MARK: - JavascriptDelegate

extension WebViewController: JavascriptDelegate {

    func javascriptShowTitleDidChange(title: String?) {
        fullTitleDidChange(title, episodeTitle: javascript.episodeTitle)
    }

    func javascriptEpisodeTitleDidChange(title: String?) {
        fullTitleDidChange(javascript.showTitle, episodeTitle: title)
    }

    private func fullTitleDidChange(showTitle: String?, episodeTitle: String?) {
        guard let windowController = view.window?.windowController as? MainWindowController else {
            return
        }

        guard let showTitle = showTitle, episodeTitle = episodeTitle else {
            return windowController.episodeTitleToolbarTextFieldCell.title = ""
        }

        let attributedTitle = NSMutableAttributedString()

        attributedTitle.appendAttributedString(NSAttributedString(string: showTitle, attributes: [
            NSFontAttributeName: NSFont.systemFontOfSize(13)
        ]))

        attributedTitle.appendAttributedString(NSAttributedString(string: " ", attributes: [
            NSFontAttributeName: NSFont.systemFontOfSize(13)
        ]))

        attributedTitle.appendAttributedString(NSAttributedString(string: episodeTitle, attributes: [
            NSFontAttributeName: NSFont.boldSystemFontOfSize(13)
        ]))

        windowController.episodeTitleToolbarTextFieldCell.attributedStringValue = attributedTitle

        if attributedTitle.length > 0 {
            let rect = attributedTitle.boundingRectWithSize(
                NSSize(width: CGFloat.max, height: CGFloat.max),
                options: [.UsesLineFragmentOrigin, .UsesFontLeading]
            )

            windowController.episodeTitleToolbarItem.minSize.width = ceil(rect.size.width) + 16
            windowController.episodeTitleToolbarItem.maxSize.width = ceil(rect.size.width) + 16
        }
    }

    func javascriptRemainingTimeDidChange(remainingTime: String?) {
        guard let windowController = view.window?.windowController as? MainWindowController else {
            return
        }

        guard let remainingTime = remainingTime else {
            return windowController.remainingTimeToolbarTextFieldCell.title = ""
        }

        windowController.remainingTimeToolbarTextFieldCell.title = remainingTime
    }

    func javascriptCurrentPercentageDidChange(currentPercentage: Float) {
        updateProgressBarView(currentPercentage)
    }

    func javascriptIsPlayingDidChange(isPlaying: Bool) {
        guard let windowController = view.window?.windowController as? MainWindowController else {
            return
        }

        if let isPlayerOpen = javascript.isPlayerOpen where !isPlayerOpen {
            windowController.playerSegmentedControl.setLabel("▶❙❙", forSegment: 1)
        } else if isPlaying {
            windowController.playerSegmentedControl.setLabel("❙❙", forSegment: 1)
        } else {
            windowController.playerSegmentedControl.setLabel("▶", forSegment: 1)
        }
    }

    func javascriptIsPlayerOpenDidChange(isPlayerOpen: Bool) {
        guard let windowController = view.window?.windowController as? MainWindowController else {
            return
        }

        if isPlayerOpen {
            windowController.playerSegmentedControl.enabled = true
            windowController.playerCloseButton.enabled = true
            javascriptIsPlayingDidChange(javascript.isPlaying ?? false)
        } else {
            windowController.playerSegmentedControl.enabled = false
            windowController.playerCloseButton.enabled = false
            windowController.playerSegmentedControl.setLabel("▶❙❙", forSegment: 1)
        }
    }

}
