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
        var episodeTitle: String? = nil
        let javascript = "angular.element(document).injector().get('mediaPlayer').episode.title"

        webView.evaluateJavaScript(javascript) { (data, error) in
            episodeTitle = (data as? String) ?? ""
//            print("episodeTitle: \(data as? String)")
//            print("error: \(error)")
        }

        while episodeTitle == nil {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }

        return episodeTitle!
    }

    var remainingTime: String {
        var remainingTime: String? = nil
        let javascript = "document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText"

        webView.evaluateJavaScript(javascript) { (data, error) in
            remainingTime = (data as? String) ?? ""
//            print("remainingTime: \(data as? String)")
//            print("error: \(error)")
        }

        while remainingTime == nil {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }

        return remainingTime!
    }

    var isPlaying: Bool {
        var value: Bool? = nil
        let javascript = "angular.element(document).injector().get('mediaPlayer').playing"

        webView.evaluateJavaScript(javascript) { (data, error) in
            value = (data as? Bool) ?? false
//            print("isPlaying: \(data as? Bool)")
//            print("error: \(error)")
        }

        while value == nil {
            NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }

        return value!
    }

    var isPlayerOpen: Bool {
        return (episodeTitle != "")
    }

    func hideToolbar() {
        webView.evaluateJavaScript("document.getElementById('header').style.top = '-70px';") { _ in } /* header height */
        webView.evaluateJavaScript("document.getElementById('main').style.paddingTop = 0;") { _ in }
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

}
