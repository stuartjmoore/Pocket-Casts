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

    let webView: WebView

    init(webView: WebView) {
        self.webView = webView
    }

    var episodeTitle: String {
        let javascript = "angular.element(document).injector().get('mediaPlayer').episode.title"
        return webView.stringByEvaluatingJavaScriptFromString(javascript)
    }

    var remainingTime: String {
        let javascript = "document.getElementById('audio_player').getElementsByClassName('remaining_time')[0].innerText"
        return webView.stringByEvaluatingJavaScriptFromString(javascript)
    }

    var isPlaying: Bool {
        let javascript = "angular.element(document).injector().get('mediaPlayer').playing"
        return (webView.stringByEvaluatingJavaScriptFromString(javascript) == "true")
    }

    var isPlayerOpen: Bool {
        return (episodeTitle != "")
    }

    func hideToolbar() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('header').style.top = '-70px';") /* header height */
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingTop = 0;")
    }

    func changeFont() {
        webView.stringByEvaluatingJavaScriptFromString("document.body.style.fontFamily = '-apple-system';")
    }

    func searchText(text: String) {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('search_input_value').value = '\(text)';")
        // angular.element("#search_input_value").scope().inputChangeHandler("alison")
        //
        // TODO: fire onChange()
    }

    func clickSettingsButton() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('dropdown-toggle')[0].firstChild.click();")
    }

    func hidePlayer() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingBottom = 0;")
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('audio_player').style.display = 'none';")
    }

    func showPlayer() {
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('main').style.paddingBottom = '66px';")
        webView.stringByEvaluatingJavaScriptFromString("document.getElementById('audio_player').style.display = 'block';")
    }

    func playPause() {
        webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').playPause()")
    }

    func jumpForward() {
        webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpForward()")
    }

    func jumpBack() {
        webView.stringByEvaluatingJavaScriptFromString("angular.element(document).injector().get('mediaPlayer').jumpBack()")
    }

}
