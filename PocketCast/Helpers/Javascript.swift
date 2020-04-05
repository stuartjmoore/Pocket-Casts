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
    func javascriptAlbumArtDidChange(_ url: URL?)
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

    fileprivate let playerString = "document.getElementsByTagName('audio')[0]"
    fileprivate let leftControlsString = "document.getElementsByClassName('player-controls')[0].getElementsByClassName('controls-left')[0]"
    fileprivate let centerControlsString = "document.getElementsByClassName('player-controls')[0].getElementsByClassName('controls-center')[0]"

    fileprivate let webView: WKWebView
    fileprivate var updatePropertiesTimer: Timer!

    weak var delegate: JavascriptDelegate?

    var albumArtURL: URL? { didSet(oldValue) { if oldValue != albumArtURL { delegate?.javascriptAlbumArtDidChange(albumArtURL) } } }
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

    var durationTimeInterval: TimeInterval = 0 {
        didSet(oldValue) {
            if oldValue != durationTimeInterval {
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

    enum Key: Int {
        case spacebar = 32 // Play/Pause
        case left = 37 // Skip backward
        case right = 39 // Skip forward
        case one = 49 // Open Podcasts section
        case two = 50 // Open Discover section
        case three = 51 // Open New Releases section
        case four = 52 // Open In Progress section
        case five = 53 // Open Star section
        case six = 54 // Open Settings section
        case e = 69 // Open playing episode popup
        case u = 85 // Open Up Next
        /*
        m - Mute sound
        minus - Reduce speed
        plus - Increase speed
        s - Search
        t - Change theme
        */
    }

    func press(key: Key) {
        switch key {
        case .one: // Open Podcasts section
            webView.evaluateJavaScript("document.getElementsByTagName('a')[1].click()") { (any, error) in
                print(any ?? error ?? "")
            }
        case .two: // Open Discover section
            webView.evaluateJavaScript("document.getElementsByTagName('a')[2].click()") { (any, error) in
                print(any ?? error ?? "")
            }
        case .three: // Open New Releases section
            webView.evaluateJavaScript("document.getElementsByTagName('a')[3].click()") { (any, error) in
                print(any ?? error ?? "")
            }
        case .four: // Open In Progress section
            webView.evaluateJavaScript("document.getElementsByTagName('a')[4].click()") { (any, error) in
                print(any ?? error ?? "")
            }
        case .five: // Open Star section
            webView.evaluateJavaScript("document.getElementsByTagName('a')[5].click()") { (any, error) in
                print(any ?? error ?? "")
            }
        default:
            ()
        }
    }

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
            selector: #selector(updatePropertiesTimerDidFire),
            userInfo: nil,
            repeats: true
        )
    }

    // MARK: - Timers

    @objc func updatePropertiesTimerDidFire() {
        webView.evaluateJavaScript("\(leftControlsString).getElementsByClassName('podcast-image')[0].getElementsByTagName('img')[0]['src']") { [weak self] (data, _) in
            guard let urlString = data as? String, let albumArtURL = URL(string: urlString) else {
                return
            }

            self?.albumArtURL = albumArtURL
        }

        webView.evaluateJavaScript("\(centerControlsString).getElementsByClassName('podcast-title')[0].innerText") { [weak self] (data, _) in
            self?.showTitle = data as? String
        }

        webView.evaluateJavaScript("\(centerControlsString).getElementsByClassName('episode-title')[0].innerText") { [weak self] (data, _) in
            self?.episodeTitle = data as? String
        }

        webView.evaluateJavaScript("\(centerControlsString).getElementsByClassName('time-remaining')[0].innerText") { [weak self] (data, _) in
            let remainingTimeDisplay = data as? String
            self?.remainingTime = remainingTimeDisplay != "-00:00" ? remainingTimeDisplay : nil
        }

        webView.evaluateJavaScript("\(playerString).currentTime") { [weak self] (data, _) in
            self?.currentTimeInterval = data as? TimeInterval ?? 0
        }

        webView.evaluateJavaScript("\(playerString).duration") { [weak self] (data, _) in
            self?.durationTimeInterval = data as? TimeInterval ?? 0
        }

        webView.evaluateJavaScript("\(playerString).paused") { [weak self] (data, _) in
            let isPaused = data as? Bool ?? false

            if self?.episodeTitle == nil {
                self?.playerState = .stopped
            } else if isPaused {
                self?.playerState = .paused
            } else {
                self?.playerState = .playing
            } // TODO: add .Buffering
        }
    }

    // MARK: -

    var currentPercentage: Float {
        let percentage = Float(currentTimeInterval / durationTimeInterval)
        return percentage.isFinite ? max(0, min(percentage, 1)) : 0
    }

    // MARK: -

    func playPause() {
        webView.evaluateJavaScript("\(playerString).paused ? \(playerString).play() : \(playerString).pause();") { (any, error) in
            print(any ?? error ?? "")
        }
    }

    func jumpForward() {
        webView.evaluateJavaScript("\(playerString).currentTime += 30;") { (any, error) in
            print(any ?? error ?? "")
        }
    }

    func jumpBack() {
        webView.evaluateJavaScript("\(playerString).currentTime -= 15;") { (any, error) in
            print(any ?? error ?? "")
        }
    }

    func jump(toPercentage percentage: Double) {
        let timeInterval = percentage * durationTimeInterval

        webView.evaluateJavaScript("\(playerString).currentTime = \(timeInterval)") { (any, error) in
            print(any ?? error ?? "")
        }
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
            RunLoop.current.run(mode: .default, before: .distantFuture)
        }

        return value
    }

}

extension JavascriptDelegate {

    func javascriptAlbumArtDidChange(_ url: URL?) {
        return
    }

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
