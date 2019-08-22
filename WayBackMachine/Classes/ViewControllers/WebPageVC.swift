//
//  OfferViewController.swift
//  WM
//
//  Created by Admin on 07/02/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import WebKit
import MBProgressHUD

class WebPageVC: UIViewController, WKUIDelegate, WKNavigationDelegate, MBProgressHUDDelegate {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var navBarHeight: NSLayoutConstraint!
    
    var webView: WKWebView?
    var progressHUD: MBProgressHUD?
    var url:String = ""
    var saveToMyWebArchive = false
    let webStorage = WKWebsiteDataStore.default()
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        webView?.frame = containerView.bounds
        self.containerView.addSubview(webView!)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WMGlobal.adjustNavBarHeight(constraint: navBarHeight)
        
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
            UserDefaults.standard.register(defaults: ["UserAgent": "Wayback_Machine_iOS/\(version!)"])
            webView?.load(request)
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func _onBack(_ sender: Any) {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        exit(0)
    }

    @IBAction func _onOpen(_ sender: Any) {
        
    }
    
    @IBAction func onShare(_ sender: Any) {
        if (url.isEmpty) {
            return
        }
        
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
    
    // MARK: - Delegates
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressHUD?.hide(animated: true)
        
        if let userData = WMGlobal.getUserData(),
            let logged_in_user = userData["logged-in-user"] as? HTTPCookie,
            let logged_in_sig = userData["logged-in-sig"] as? HTTPCookie,
            self.saveToMyWebArchive == true {
            
            guard let url = webView.url?.absoluteString else { return }
            do {
                let regex = try NSRegularExpression(pattern: "http[s]?:\\/\\/web.archive.org\\/web\\/(.*?)\\/(.*)", options: [])
                let results = regex.matches(in: url, range: NSRange(url.startIndex..., in: url))
                
                guard results.count != 0 else {
                    return
                }
                
                let snapshotUrlRange = results[0].range(at: 2)
                let snapshotRange = results[0].range(at: 1)
                
                guard
                let snapshotUrl = url.slicing(from: snapshotUrlRange.location, length: snapshotUrlRange.length),
                    let snapshot = url.slicing(from: snapshotRange.location, length: snapshotRange.length) else {
                        return
                }
                
                WMAPIManager.sharedManager.saveToMyWebArchive(url: snapshotUrl, snapshot: snapshot, logged_in_user: logged_in_user, logged_in_sig: logged_in_sig) { (success) in
                    print(success)
                }
            } catch {
                print("Invalid regex")
            }
        }
    }

}