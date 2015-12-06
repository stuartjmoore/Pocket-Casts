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

    var episodeTitle: String {
        return valueFor("angular.element(document).injector().get('mediaPlayer').episode.title") as? String ?? ""
    }

    var remainingTime: String {
        return valueFor("document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText") as? String ?? ""
    }

    var isPlaying: Bool {
        return valueFor("angular.element(document).injector().get('mediaPlayer').playing") as? Bool ?? false
    }

    var isPlayerOpen: Bool {
        return (episodeTitle != "")
    }

    func hideToolbar() {
        webView.evaluateJavaScript("document.getElementById('header').style.boxShadow = '0 0 0 0 white';", completionHandler:  nil)
        webView.evaluateJavaScript("document.getElementById('header').style.webkitBoxShadow = '0 0 0 0 white';", completionHandler:  nil)
        webView.evaluateJavaScript("document.getElementById('header').style.top = '-70px';", completionHandler:  nil)
        webView.evaluateJavaScript("document.getElementById('main').style.paddingTop = 0;", completionHandler:  nil)
    }

    func changeFont() {
        webView.evaluateJavaScript("document.body.style.fontFamily = '-apple-system';") { _ in }
    }

    func searchText(text: String) {
        webView.evaluateJavaScript("document.getElementById('search_input_value').value = '\(text)';") { _ in }
        // angular.element("#search_input_value").scope().inputChangeHandler("alison")
        //
        // TODO: fire onChange()
    }

    func clickSettingsButton() {
        webView.evaluateJavaScript("document.getElementsByClassName('dropdown-toggle')[0].firstChild.click();") { _ in }
    }

    func hidePlayer() {
        webView.evaluateJavaScript("document.getElementById('main').style.paddingBottom = 0;") { _ in }
        webView.evaluateJavaScript("document.getElementById('audio_player').style.display = 'none';") { _ in }
    }

    func showPlayer() {
        webView.evaluateJavaScript("document.getElementById('main').style.paddingBottom = '66px';") { _ in }
        webView.evaluateJavaScript("document.getElementById('audio_player').style.display = 'block';") { _ in }
    }

    func playPause() {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').playPause()") { _ in }
    }

    func jumpForward() {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').jumpForward()") { _ in }
    }

    func jumpBack() {
        webView.evaluateJavaScript("angular.element(document).injector().get('mediaPlayer').jumpBack()") { _ in }
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
