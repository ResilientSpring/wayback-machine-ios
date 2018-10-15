//
//  WebPageVC.swift
//  WM
//
//  Created by mac-admin on 8/10/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit
import MBProgressHUD

open class WebPageVC: UIViewController, WKUIDelegate, WKNavigationDelegate, MBProgressHUDDelegate {

    
    @IBOutlet weak var containerView: UIView!
    var webView: WKWebView?
    var progressHUD: MBProgressHUD?
    open var url: String = ""
    let webStorage = WKWebsiteDataStore.default()
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
    
    override open func loadView() {
        super.loadView()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        webView?.frame = containerView.bounds
        self.containerView.addSubview(webView!)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        if (!url.isEmpty) {
            self.progressHUD = MBProgressHUD(view: self.view)
            self.progressHUD!.bezelView.color = UIColor.clear
            self.view.addSubview(progressHUD!)
            self.progressHUD!.delegate = self
            self.progressHUD!.show(animated: true)
            
            var request = URLRequest(url: URL(string: url)!)
            if let userData = WMGlobal.getUserData(),
                let loggedInUser = userData["logged-in-user"] as? HTTPCookie,
                let loggedInSig = userData["logged-in-sig"] as? HTTPCookie
            {
                if #available(iOS 11.0, *) {
                    webStorage.httpCookieStore.setCookie(loggedInSig, completionHandler: nil)
                    webStorage.httpCookieStore.setCookie(loggedInUser, completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                }
            }
            request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "User-Agent")
            request.setValue("Wayback_Machine_iOS/\(version!)", forHTTPHeaderField: "Wayback-Extension-Version")
            webView?.load(request)
        }
    }
    
    @IBAction func _onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func _onShare(_ sender: Any) {
        if url.isEmpty { return }
        
        self.displayShareSheet(url: (webView?.url?.absoluteString)!)
    }
    
    func displayShareSheet(url: String) {
        let text = "Archived in the Wayback Machine at: "
        
        let activityViewController = UIActivityViewController(activityItems: [text, url as NSString], applicationActivities: nil)
        
        
        activityViewController.completionWithItemsHandler = {
            (activityType, completed, returnedItems, err) -> Void in
            
            if (completed) {
                self.displayShareSheet(url: url)
            }
        }
        
        self.present(activityViewController, animated: true, completion: {})
    }
    
    // MARK: - WKWebView Delegates
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressHUD?.hide(animated: true)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}