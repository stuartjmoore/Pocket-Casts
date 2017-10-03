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

    fileprivate var javascript: Javascript!
    fileprivate var loginSheet: NSPanel!
    fileprivate var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let sourceCSS = String(resource: "stylesheet", withExtension: "css") {
            let sourceJS = Javascript.sourceFromCSS(sourceCSS)
            let userScript = WKUserScript(source: sourceJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            let userContentController = WKUserContentController()
            userContentController.addUserScript(userScript)

            let configuration = WKWebViewConfiguration()
            configuration.userContentController = userContentController

            webView = WKWebView(frame: view.bounds, configuration: configuration)
        } else {
            webView = WKWebView(frame: view.bounds)
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView, positioned: .below, relativeTo: nil)

        view.topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: webView.leadingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: webView.bottomAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: webView.trailingAnchor).isActive = true

        if let pocketCastsURL = URL(string: "https://playbeta.pocketcasts.com/web/new-releases") {
            let pocketCastsRequest = URLRequest(url: pocketCastsURL)
            webView.load(pocketCastsRequest)
        } else {
            fatalError("Unable to create Pocket Casts URL.")
        }

        javascript = Javascript(webView: webView)
        javascript.delegate = self
    }

    func loadRequest(_ request: URLRequest) {
        webView.load(request)
    }

    // MARK: - Javascript

    var isPlaying: Bool {
        return javascript.playerState == .playing
    }

    func timeInterval(atPercentage percentage: Double) -> TimeInterval {
        return percentage * javascript.durationTimeInterval
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

    func jump(toPercentage percentage: Double) {
        javascript.jump(toPercentage: percentage)
    }

    // MARK: UI

    func showUpNext() {
        javascript.press(key: .u)
    }

}

// MARK: - JavascriptDelegate

extension WebViewController: JavascriptDelegate {

    var windowController: MainWindowController? {
        return view.window?.windowController as? MainWindowController
    }

    func javascriptShowTitleDidChange(_ showTitle: String?) {
        windowController?.showTitle = showTitle
    }

    func javascriptEpisodeTitleDidChange(_ episodeTitle: String?) {
        windowController?.episodeTitle = episodeTitle
    }

    func javascriptRemainingTimeDidChange(_ remainingTime: String?) {
        windowController?.remainingTimeText = remainingTime
    }

    func javascriptCurrentPercentageDidChange(_ currentPercentage: Float) {
        windowController?.progressPercentage = currentPercentage

        if let dockView = NSApplication.shared.dockTile.contentView as? DockProgressView {
            dockView.percentage = currentPercentage
            NSApp.dockTile.display()
        } else {
            let dockView = DockProgressView()
            dockView.percentage = currentPercentage

            NSApplication.shared.dockTile.contentView = dockView
            NSApp.dockTile.display()
        }
    }

    func javascriptPlayerStateDidChange(_ playerState: PlayerState) {
        windowController?.playerState = playerState
    }

}

// MARK: -

extension String {
    init?(resource: String, withExtension: String) {
        guard let resourceURL = Bundle.main.url(forResource: resource, withExtension: withExtension) else {
            return nil
        }

        guard let resourceString = try? String(contentsOf: resourceURL, encoding: .utf8) else {
            return nil
        }

        self = resourceString
    }
}
