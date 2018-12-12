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

    fileprivate var webView: WKWebView!

    var request: URLRequest? {
        didSet {
            if let request = request {
                webView?.load(request)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView, positioned: .below, relativeTo: nil)

        view.topAnchor.constraint(equalTo: webView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: webView.leadingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: webView.bottomAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: webView.trailingAnchor).isActive = true

        if let request = request {
            webView.load(request)
        }
    }

}

// MARK: - WKNavigationDelegate

extension LoginViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url?.path == "/web" {
            (presentingViewController as? WebViewController)?.loadRequest(navigationAction.request)
            presentingViewController?.dismiss(self)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

}
