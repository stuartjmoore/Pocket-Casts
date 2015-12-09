//
//  MainViewController.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 12/8/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa
import WebKit

class MainViewController: NSViewController {

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressLayoutConstraint: NSLayoutConstraint!

    var loginSheet: NSPanel!
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        progressView.wantsLayer = true

        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView, positioned: .Below, relativeTo: progressView)

        /* window.frame.height + window.contentLayoutRect.maxY */
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
    }

    override func awakeFromNib() {
        progressView.layer?.backgroundColor = NSColor(red: 1, green: 0.373, blue: 0.31, alpha: 1).CGColor
    }

    func updateProgressBarView(percentage: Float) {
        progressLayoutConstraint.constant = view.frame.width * CGFloat(percentage)
    }

    // MARK: -

    var showTitle: String? {
        return Javascript(webView: webView).showTitle
    }

    var episodeTitle: String? {
        return Javascript(webView: webView).episodeTitle
    }

    var remainingTime: String? {
        return Javascript(webView: webView).remainingTime
    }

    var isPlayerOpen: Bool {
        return Javascript(webView: webView).isPlayerOpen
    }

    var isPlaying: Bool {
        return Javascript(webView: webView).isPlaying
    }

    var currentPercentage: Float {
        return Javascript(webView: webView).currentPercentage
    }

    // MARK: -

    func jumpBack() {
        Javascript(webView: webView).jumpBack()
    }

    func playPause() {
        Javascript(webView: webView).playPause()
    }

    func jumpForward() {
        Javascript(webView: webView).jumpForward()
    }

    func clickSettingsButton() {
        Javascript(webView: webView).clickSettingsButton()
    }

    func hidePlayer() {
        Javascript(webView: webView).hidePlayer()
    }

    func showPlayer() {
        Javascript(webView: webView).showPlayer()
    }

}

extension MainViewController: WKNavigationDelegate {

    func webView(webView: WKWebView, didFinishNavigation: WKNavigation!) {
        Javascript(webView: webView).hideToolbar()
        Javascript(webView: webView).changeFont()
    }
/*
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if webView === self.webView && navigationAction.request.URL?.path == "/users/sign_in" {
            loginSheet = NSPanel()

            if let rect = window.contentView?.bounds {
                loginSheet.setContentSize(rect.insetBy(dx: 44, dy: 22).size)
            }

            let loginWebView = WKWebView(frame: loginSheet.contentView?.bounds ?? .zero)
            loginWebView.navigationDelegate = self
            loginWebView.translatesAutoresizingMaskIntoConstraints = false
            loginSheet.contentView?.addSubview(loginWebView)

            loginSheet.contentView?.topAnchor.constraintEqualToAnchor(loginWebView.topAnchor).active = true
            loginSheet.contentView?.leadingAnchor.constraintEqualToAnchor(loginWebView.leadingAnchor).active = true
            loginSheet.contentView?.bottomAnchor.constraintEqualToAnchor(loginWebView.bottomAnchor).active = true
            loginSheet.contentView?.trailingAnchor.constraintEqualToAnchor(loginWebView.trailingAnchor).active = true

            loginWebView.loadRequest(navigationAction.request)
            window.beginSheet(loginSheet, completionHandler: nil)
            decisionHandler(.Cancel)
        } else if webView !== self.webView && navigationAction.request.URL?.path == "/web" {
            self.webView.loadRequest(navigationAction.request)
            window.endSheet(loginSheet)
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }
*/
}
