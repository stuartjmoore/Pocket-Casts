//
//  Javascript.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 12/2/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Foundation
import WebKit

class Javascript {

    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    var showTitle: String? {
        return valueFor("angular.element(document).injector().get('mediaPlayer').episode.podcast.title") as? String
    }

    var episodeTitle: String? {
        return valueFor("angular.element(document).injector().get('mediaPlayer').episode.title") as? String
    }

    var remainingTime: String? {
        let javascriptString = "document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText"

        guard let remainingTime = valueFor(javascriptString) as? String where remainingTime != "-00:00" else {
            return nil
        }

        return remainingTime
    }

    var currentTimeInterval: NSTimeInterval {
        return valueFor("angular.element(document).injector().get('mediaPlayer').currentTime") as? NSTimeInterval ?? 0
    }

    var remainingTimeInterval: NSTimeInterval {
        return valueFor("angular.element(document).injector().get('mediaPlayer').remainingTime") as? NSTimeInterval ?? 0
    }

    var bufferStartTimeInterval: NSTimeInterval {
        return valueFor("angular.element(document).injector().get('mediaPlayer').bufferStart") as? NSTimeInterval ?? 0
    }

    var bufferEndTimeInterval: NSTimeInterval {
        return valueFor("angular.element(document).injector().get('mediaPlayer').bufferEnd") as? NSTimeInterval ?? 0
    }

    var currentPercentage: Float {
        let currentTimeInterval = self.currentTimeInterval
        let remainingTimeInterval = self.remainingTimeInterval
        let percentage = Float(currentTimeInterval / (currentTimeInterval + remainingTimeInterval))

        guard percentage.isFinite else {
            return 0
        }

        return max(0, min(percentage, 1))
    }

    var isPlaying: Bool {
        return valueFor("angular.element(document).injector().get('mediaPlayer').playing") as? Bool ?? false
    }

    var isPlayerOpen: Bool {
        return (episodeTitle != nil)
    }

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
