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
    func javascriptShowTitleDidChange(_ title: String?)
    func javascriptEpisodeTitleDidChange(_ title: String?)
    func javascriptRemainingTimeDidChange(_ remainingTime: String?)

    func javascriptCurrentPercentageDidChange(_ currentPercentage: Float)
    func javascriptPlayerStateDidChange(_ playerState: PlayerState)
}

enum PlayerState {
    case stopped, buffering, playing, paused
}

class Javascript {

    fileprivate let webView: WKWebView
    fileprivate var updatePropertiesTimer: Timer!

    weak var delegate: JavascriptDelegate?

    var showTitle: String? { didSet(oldValue) { if oldValue != showTitle { delegate?.javascriptShowTitleDidChange(showTitle) } } }
    var episodeTitle: String? { didSet(oldValue) { if oldValue != episodeTitle { delegate?.javascriptEpisodeTitleDidChange(episodeTitle) } } }
    var remainingTime: String? { didSet(oldValue) { if oldValue != remainingTime { delegate?.javascriptRemainingTimeDidChange(remainingTime) } } }

    var currentTimeInterval: TimeInterval = 0 {
        didSet(oldValue) {
            if oldValue != currentTimeInterval {
                delegate?.javascriptCurrentPercentageDidChange(currentPercentage)
            }
        }
    }

    var remainingTimeInterval: TimeInterval = 0 {
        didSet(oldValue) {
            if oldValue != remainingTimeInterval {
                delegate?.javascriptCurrentPercentageDidChange(currentPercentage)
            }
        }
    }

    var playerState: PlayerState? {
        didSet(oldValue) {
            if let playerState = playerState, oldValue != playerState {
                delegate?.javascriptPlayerStateDidChange(playerState)
            }
        }
    }

    // MARK: -

    class func sourceFromCSS(_ css: String) -> String {
        let strippedCSS = css.replacingOccurrences(of: "\n", with: " ")
        return "var styleTag = document.createElement('style');" +
               "styleTag.textContent = '\(strippedCSS)';" +
               "document.documentElement.appendChild(styleTag);"
    }

    // MARK: -

    init(webView: WKWebView) {
        self.webView = webView

        updatePropertiesTimer = Timer.scheduledTimer(timeInterval: 0.5,
            target: self,
            selector: #selector(updatePropertiesTimerDidFire(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    // MARK: - Timers

    @objc fileprivate func updatePropertiesTimerDidFire(_ timer: Timer) {
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
            self?.currentTimeInterval = data  as? TimeInterval ?? 0
        }

        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').remainingTime") { [weak self] (data, _) in
            self?.remainingTimeInterval = data  as? TimeInterval ?? 0
        }

        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').playing") { [weak self] (data, _) in
            let isPlaying = data  as? Bool ?? false

            if self?.episodeTitle == nil {
                self?.playerState = .stopped
            } else if isPlaying {
                self?.playerState = .playing
            } else {
                self?.playerState = .paused
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

        guard let paddingBottom = Int(paddingBottomString.trimmingCharacters(in: .letters)) else {
            return false
        }

        return (paddingBottom != 0)
    }

    // MARK: -

    enum MenuItem {
        case link(String, URL)
        case action(String, String)
        case separator
    }

    var settingsMenuItems: [MenuItem] {
        guard let titleStrings = valueFor("Array.prototype.slice.call(document.getElementById('header').getElementsByClassName('dropdown-menu')[0].getElementsByTagName('li')).map(function(node) { return node.innerText })") as? [String] else {
            return []
        }

        guard let actionStrings = valueFor("Array.prototype.slice.call(document.getElementById('header').getElementsByClassName('dropdown-menu')[0].getElementsByTagName('li')).map(function(node) { return node.firstChild ? (node.firstChild.href ? node.firstChild.href : (node.firstChild.attributes.getNamedItem('ng-click') ? node.firstChild.attributes.getNamedItem('ng-click').value : '')) : '' })") as? [String] else {
            return []
        }

        let titles: [String?] = titleStrings.map({ $0 == "" ? nil : $0.trimmingCharacters(in: .newlines) })
        let actions: [String?] = actionStrings.map({ $0 == "" ? nil : $0 })

        let items: [MenuItem] = zip(titles, actions).map({ (title, action) in
            if let title = title, let action = action, let url = URL(string: action) /* TODO: where hasPrefix("http") */ {
                return .link(title, url)
            } else if let title = title, let action = action {
                return .action(title, action)
            } else {
                return .separator
            }
        })

        return items
    }

    // MARK: -

    func searchText(_ text: String) {
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

    fileprivate func valueFor(_ javascript: String) -> Any? {
        var value: Any?
        var finished = false

        webView.evaluateJavaScript(javascript) { (data, _) in
            value = data
            finished = true
        }

        while !finished {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
        }

        return value
    }

}

extension JavascriptDelegate {

    func javascriptShowTitleDidChange(_ title: String?) {
        return
    }

    func javascriptEpisodeTitleDidChange(_ title: String?) {
        return
    }

    func javascriptRemainingTimeDidChange(_ remainingTime: String?) {
        return
    }

    func javascriptCurrentPercentageDidChange(_ currentPercentage: Float) {
        return
    }

    func javascriptPlayerStateDidChange(_ playerState: PlayerState) {
        return
    }
    
}
