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

    private var javascript: Javascript!
    private var loginSheet: NSPanel!
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let sourceCSS = String(resource: "stylesheet", withExtension: "css") {
            let sourceJS = Javascript.sourceFromCSS(sourceCSS)
            let userScript = WKUserScript(source: sourceJS, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
            let userContentController = WKUserContentController()
            userContentController.addUserScript(userScript)

            let configuration = WKWebViewConfiguration()
            configuration.userContentController = userContentController

            webView = WKWebView(frame: view.bounds, configuration: configuration)
        } else {
            webView = WKWebView(frame: view.bounds)
        }

        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView, positioned: .Below, relativeTo: nil)

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

    func loadRequest(request: NSURLRequest) {
        webView.loadRequest(request)
    }

    // MARK: - Javascript

    var isPlaying: Bool {
        return javascript.playerState == .Playing
    }

    var playerVisible: Bool {
        return javascript.playerVisible
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
        /*
        let menu = NSMenu(title: "Settings")

        for item in javascript.settingsMenuItems {
            switch item {
            case .Link(let title, _):
                menu.addItemWithTitle(title, action: "settingMenuDidSelect:", keyEquivalent: "")
            case .Action(let title, _):
                menu.addItemWithTitle(title, action: "settingMenuDidSelect:", keyEquivalent: "")
            case .Separator:
                menu.addItem(NSMenuItem.separatorItem())
            }
        }

        menu.popUpMenuPositioningItem(nil, atLocation: NSEvent.mouseLocation(), inView: nil)
        */
    }

    func settingMenuDidSelect(menuItem: NSMenuItem) {
        if let index = menuItem.menu?.indexOfItem(menuItem) {
            let item = javascript.settingsMenuItems[index]
            switch item {
            case .Link(_, let url):
                // TODO: sign out doesn't work
                NSWorkspace.sharedWorkspace().openURL(url)
            case .Action(_, _):
                // TODO: action
                break
            case .Separator:
                break
            }
        }
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

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.URL?.path == "/account", let url = navigationAction.request.URL {
            NSWorkspace.sharedWorkspace().openURL(url)
            decisionHandler(.Cancel)
        } else if navigationAction.request.URL?.path == "/users/sign_in" {
            performSegueWithIdentifier("LoginSheetIdentifier", sender: navigationAction.request)
            decisionHandler(.Cancel)
        } else if navigationAction.navigationType == .LinkActivated, let url = navigationAction.request.URL {
            NSWorkspace.sharedWorkspace().openURL(url)
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

    var windowController: MainWindowController? {
        return view.window?.windowController as? MainWindowController
    }

    func javascriptShowTitleDidChange(showTitle: String?) {
        windowController?.showTitle = showTitle
    }

    func javascriptEpisodeTitleDidChange(episodeTitle: String?) {
        windowController?.episodeTitle = episodeTitle
    }

    func javascriptRemainingTimeDidChange(remainingTime: String?) {
        windowController?.remainingTimeText = remainingTime
    }

    func javascriptCurrentPercentageDidChange(currentPercentage: Float) {
        windowController?.progressPercentage = currentPercentage
    }

    func javascriptPlayerStateDidChange(playerState: PlayerState) {
        windowController?.playerState = playerState

        if playerState == .Paused || playerState == .Playing  {
            windowController?.playerVisible = javascript.playerVisible
        }
    }

}

// MARK: -

extension String {
    init?(resource: String, withExtension: String) {
        guard let resourceURL = NSBundle.mainBundle().URLForResource(resource, withExtension: withExtension) else {
            return nil
        }

        guard let resourceString = try? NSString(contentsOfURL: resourceURL, encoding: NSUTF8StringEncoding) as String else {
            return nil
        }

        self = resourceString
    }
}
