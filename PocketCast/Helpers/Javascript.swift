//
//  Javascript.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 12/2/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Foundation
import WebKit

protocol JavascriptDelegate: class {
    func javascriptShowTitleDidChange(title: String?)
    func javascriptEpisodeTitleDidChange(title: String?)
    func javascriptRemainingTimeDidChange(remainingTime: String?)

    func javascriptCurrentPercentageDidChange(currentPercentage: Float)
    func javascriptPlayerStateDidChange(playerState: PlayerState)
}

enum PlayerState {
    case Stopped, Buffering, Playing, Paused
}

class Javascript {

    private let webView: WKWebView
    private var updatePropertiesTimer: NSTimer!

    weak var delegate: JavascriptDelegate?

    var showTitle: String? { didSet(oldValue) { if oldValue != showTitle { delegate?.javascriptShowTitleDidChange(showTitle) } } }
    var episodeTitle: String? { didSet(oldValue) { if oldValue != episodeTitle { delegate?.javascriptEpisodeTitleDidChange(episodeTitle) } } }
    var remainingTime: String? { didSet(oldValue) { if oldValue != remainingTime { delegate?.javascriptRemainingTimeDidChange(remainingTime) } } }

    var currentTimeInterval: NSTimeInterval = 0 {
        didSet(oldValue) {
            if oldValue != currentTimeInterval {
                delegate?.javascriptCurrentPercentageDidChange(currentPercentage)
            }
        }
    }

    var remainingTimeInterval: NSTimeInterval = 0 {
        didSet(oldValue) {
            if oldValue != remainingTimeInterval {
                delegate?.javascriptCurrentPercentageDidChange(currentPercentage)
            }
        }
    }

    var playerState: PlayerState? {
        didSet(oldValue) {
            if let playerState = playerState where oldValue != playerState {
                delegate?.javascriptPlayerStateDidChange(playerState)
            }
        }
    }

    // MARK: -

    class func sourceFromCSS(css: String) -> String {
        let strippedCSS = css.stringByReplacingOccurrencesOfString("\n", withString: " ")
        return "var styleTag = document.createElement('style');" +
               "styleTag.textContent = '\(strippedCSS)';" +
               "document.documentElement.appendChild(styleTag);"
    }

    // MARK: -

    init(webView: WKWebView) {
        self.webView = webView

        updatePropertiesTimer = NSTimer.scheduledTimerWithTimeInterval(0.5,
            target: self,
            selector: "updatePropertiesTimerDidFire:",
            userInfo: nil,
            repeats: true
        )
    }

    // MARK: - Timers

    @objc private func updatePropertiesTimerDidFire(timer: NSTimer) {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').episode.podcast.title") { [weak self] (data, _) in
            self?.showTitle = data  as? String
        }

        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').episode.title") { [weak self] (data, _) in
            self?.episodeTitle = data  as? String
        }

        webView.evaluateJavaScript("document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText") { [weak self] (data, _) in
            let remainingTimeDisplay = data  as? String
            self?.remainingTime = remainingTimeDisplay != "-00:00" ? remainingTimeDisplay : nil
        }

        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').currentTime") { [weak self] (data, _) in
            self?.currentTimeInterval = data  as? NSTimeInterval ?? 0
        }

        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').remainingTime") { [weak self] (data, _) in
            self?.remainingTimeInterval = data  as? NSTimeInterval ?? 0
        }

        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').playing") { [weak self] (data, _) in
            let isPlaying = data  as? Bool ?? false

            if self?.episodeTitle == nil {
                self?.playerState = .Stopped
            } else if isPlaying {
                self?.playerState = .Playing
            } else {
                self?.playerState = .Paused
            } // TODO: add .Buffering
        }
    }

    // MARK: -

    var currentPercentage: Float {
        let percentage = Float(currentTimeInterval / (currentTimeInterval + remainingTimeInterval))
        return percentage.isFinite ? max(0, min(percentage, 1)) : 0
    }

    var playerVisible: Bool {
        guard let paddingBottomString = valueFor("document.getElementById('main').style.paddingBottom") as? String else {
            return false
        }

        if paddingBottomString == "" {
            return true // HACK: First pass doesn’t return values
        }

        guard let paddingBottom = Int(paddingBottomString.stringByTrimmingCharactersInSet(.letterCharacterSet())) else {
            return false
        }

        return (paddingBottom != 0)
    }

    // MARK: -

    enum MenuItem {
        case Link(String, NSURL)
        case Action(String, String)
        case Separator
    }

    var settingsMenuItems: [MenuItem] {
        guard let titleStrings = valueFor("Array.prototype.slice.call(document.getElementById('header').getElementsByClassName('dropdown-menu')[0].getElementsByTagName('li')).map(function(node) { return node.innerText })") as? [String] else {
            return []
        }

        guard let actionStrings = valueFor("Array.prototype.slice.call(document.getElementById('header').getElementsByClassName('dropdown-menu')[0].getElementsByTagName('li')).map(function(node) { return node.firstChild ? (node.firstChild.href ? node.firstChild.href : (node.firstChild.attributes.getNamedItem('ng-click') ? node.firstChild.attributes.getNamedItem('ng-click').value : '')) : '' })") as? [String] else {
            return []
        }

        let titles: [String?] = titleStrings.map({ $0 == "" ? nil : $0.stringByTrimmingCharactersInSet(.newlineCharacterSet()) })
        let actions: [String?] = actionStrings.map({ $0 == "" ? nil : $0 })

        let items: [MenuItem] = zip(titles, actions).map({ (title, action) in
            if let title = title, action = action, url = NSURL(string: action) /* TODO: where hasPrefix("http") */ {
                return .Link(title, url)
            } else if let title = title, action = action {
                return .Action(title, action)
            } else {
                return .Separator
            }
        })

        return items
    }

    // MARK: -

    func searchText(text: String) {
        webView.evaluateJavaScript("document.getElementById('search_input_value').value = '\(text)';", completionHandler:  nil)
        // angular.element("#search_input_value").scope().inputChangeHandler("alison")
        //
        // TODO: fire onChange()
    }

    func clickSettingsButton() {
        webView.evaluateJavaScript("document.getElementsByClassName('dropdown-toggle')[0].firstChild.click();", completionHandler:  nil)
    }

    func hidePlayer() {
        webView.evaluateJavaScript("document.getElementById('main').style.paddingBottom = 0;" +
                                   "document.getElementById('audio_player').style.display = 'none';", completionHandler:  nil)
    }

    func showPlayer() {
        webView.evaluateJavaScript("document.getElementById('main').style.paddingBottom = '66px';" +
                                   "document.getElementById('audio_player').style.display = 'block';", completionHandler:  nil)
    }

    func playPause() {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').playPause()", completionHandler:  nil)
    }

    func jumpForward() {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').jumpForward()", completionHandler:  nil)
    }

    func jumpBack() {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').jumpBack()", completionHandler:  nil)
    }

    // MARK: -

    private func valueFor(javascript: String) -> Any? {
        var value: Any?
        var finished = false

        webView.evaluateJavaScript(javascript) { (data, _) in
            value = data
            finished = true
        }

        while !finished {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }

        return value
    }

}

extension JavascriptDelegate {

    func javascriptShowTitleDidChange(title: String?) {
        return
    }

    func javascriptEpisodeTitleDidChange(title: String?) {
        return
    }

    func javascriptRemainingTimeDidChange(remainingTime: String?) {
        return
    }

    func javascriptCurrentPercentageDidChange(currentPercentage: Float) {
        return
    }

    func javascriptPlayerStateDidChange(playerState: PlayerState) {
        return
    }
    
}
