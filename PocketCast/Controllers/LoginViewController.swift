//
//  LoginViewController.swift
//  Pocket Casts
//
//  Created by Stuart Moore on 12/8/15.
//  Copyright © 2015 Morten Just Petersen. All rights reserved.
//

import Cocoa
import WebKit

class LoginViewController: NSViewController {

    private var webView: WKWebView!

    var request: NSURLRequest? {
        didSet {
            if let request = request {
                webView?.loadRequest(request)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView, positioned: .Below, relativeTo: nil)

        view.topAnchor.constraintEqualToAnchor(webView.topAnchor).active = true
        view.leadingAnchor.constraintEqualToAnchor(webView.leadingAnchor).active = true
        view.bottomAnchor.constraintEqualToAnchor(webView.bottomAnchor).active = true
        view.trailingAnchor.constraintEqualToAnchor(webView.trailingAnchor).active = true

        if let request = request {
            webView.loadRequest(request)
        }
    }

}

// MARK: - WKNavigationDelegate

extension LoginViewController: WKNavigationDelegate {

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.URL?.path == "/web" {
            (presentingViewController as? WebViewController)?.loadRequest(navigationAction.request)
            presentingViewController?.dismissViewController(self)
            decisionHandler(.Cancel)
        } else {
            decisionHandler(.Allow)
        }
    }

}
