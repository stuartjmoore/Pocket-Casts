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

    func javascriptIsPlayingDidChange(isPlaying: Bool)
    func javascriptIsPlayerOpenDidChange(isPlayerOpen: Bool)
}

class Javascript {

    private let webView: WKWebView
    private var updatePropertiesTimer: NSTimer!

    weak var delegate: JavascriptDelegate?

    var showTitle: String? { didSet(oldValue) { if oldValue != showTitle { delegate?.javascriptShowTitleDidChange(showTitle) } } }
    var episodeTitle: String? { didSet(oldValue) { if oldValue != episodeTitle { delegate?.javascriptEpisodeTitleDidChange(episodeTitle) } } }
    var remainingTime: String? { didSet(oldValue) { if oldValue != remainingTime { delegate?.javascriptRemainingTimeDidChange(remainingTime) } } }

    var currentTimeInterval: NSTimeInterval = 0
    var remainingTimeInterval: NSTimeInterval = 0
    var bufferStartTimeInterval: NSTimeInterval = 0
    var bufferEndTimeInterval: NSTimeInterval = 0

    var currentPercentage: Float = 0 {
        didSet(oldValue) {
            if oldValue != currentPercentage {
                delegate?.javascriptCurrentPercentageDidChange(currentPercentage)
            }
        }
    }

    var isPlaying: Bool? {
        didSet(oldValue) {
            if let isPlaying = isPlaying where oldValue != isPlaying {
                delegate?.javascriptIsPlayingDidChange(isPlaying)
            }
        }
    }

    var isPlayerOpen: Bool? {
        didSet(oldValue) {
            if let isPlayerOpen = isPlayerOpen where oldValue != isPlayerOpen {
                delegate?.javascriptIsPlayerOpenDidChange(isPlayerOpen)
            }
        }
    }

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
        showTitle = valueFor("angular.element(document).injector().get('mediaPlayer').episode.podcast.title") as? String
        episodeTitle = valueFor("angular.element(document).injector().get('mediaPlayer').episode.title") as? String

        let remainingTimeDisplay = valueFor("document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText") as? String
        remainingTime = remainingTimeDisplay != "-00:00" ? remainingTimeDisplay : nil

        currentTimeInterval = valueFor("angular.element(document).injector().get('mediaPlayer').currentTime") as? NSTimeInterval ?? 0
        remainingTimeInterval = valueFor("angular.element(document).injector().get('mediaPlayer').remainingTime") as? NSTimeInterval ?? 0
        bufferStartTimeInterval = valueFor("angular.element(document).injector().get('mediaPlayer').bufferStart") as? NSTimeInterval ?? 0
        bufferEndTimeInterval = valueFor("angular.element(document).injector().get('mediaPlayer').bufferEnd") as? NSTimeInterval ?? 0

        let percentage = Float(currentTimeInterval / (currentTimeInterval + remainingTimeInterval))
        currentPercentage = percentage.isFinite ? max(0, min(percentage, 1)) : 0

        isPlaying = valueFor("angular.element(document).injector().get('mediaPlayer').playing") as? Bool ?? false
        isPlayerOpen = (episodeTitle != nil)
    }

    // MARK: -

    func hideToolbar() {
        webView.evaluateJavaScript("document.getElementById('header').style.boxShadow = '0 0 0 0 white';" +
                                   "document.getElementById('header').style.webkitBoxShadow = '0 0 0 0 white';" +
                                   "document.getElementById('header').style.top = '-70px';" +
                                   "document.getElementById('main').style.paddingTop = 0;", completionHandler:  nil)
    }

    func changeFont() {
        webView.evaluateJavaScript("document.body.style.fontFamily = '-apple-system';", completionHandler:  nil)
    }

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

    func javascriptIsPlayingDidChange(isPlaying: Bool) {
        return
    }

    func javascriptIsPlayerOpenDidChange(isPlayerOpen: Bool) {
        return
    }
    
}
