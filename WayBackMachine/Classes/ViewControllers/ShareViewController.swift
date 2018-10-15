//
//  ShareViewController.swift
//  WayBackMachine
//
//  Created by Admin on 31/01/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import AVFoundation
import Social
import MobileCoreServices
import MBProgressHUD
import FRHyperLabel

class ShareViewController: UIViewController, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate{

    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    @IBOutlet weak var uploadView: UIView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var txtSubjectTags: UITextField!
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var imgPreview: UIImageView!
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var btnCheck: UIButton!
    @IBOutlet weak var containerForCheck: UIView!
    
    var fileURL: URL?
    var fileData: Data?
    var mediaType: String?
    let serverURLForSavePage = "https://web.archive.org/save/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ------UI------
        shareView.layer.cornerRadius = 10
        urlTextField.isUserInteractionEnabled = false
        urlTextField.textAlignment = .center
        logoImageView.image = UIImage(named: "icon_logo")
        logoImageView.contentMode = .center
        logoImageView.layer.cornerRadius = logoImageView.frame.width / 2
        logoImageView.layer.masksToBounds = true
        logoImageView.layer.borderWidth = 3
        logoImageView.layer.borderColor = UIColor.white.cgColor
        logoImageView.isHidden = true
        btnSave.layer.cornerRadius = 10
        btnCancel.layer.cornerRadius = 10
        
        uploadView.layer.cornerRadius = 10
        innerView.layer.cornerRadius = 10
        txtDescription.layer.borderWidth = 1
        txtDescription.layer.cornerRadius = 5
        txtDescription.layer.borderColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor
        preview.layer.borderWidth = 1
        preview.layer.cornerRadius = 5
        preview.layer.borderColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor
        videoPreview.layer.cornerRadius = 5
        
        shareView.isHidden = true
        uploadView.isHidden = true
        
        if WMGlobal.isLoggedIn(), let userData = WMGlobal.getUserData() {
            btnCheck.isSelected = false
            if let addToMyWebArchive = userData["add-to-my-web-archive"] {
                btnCheck.isSelected = addToMyWebArchive as! Bool
            }
            containerForCheck.isHidden = false
        } else {
            containerForCheck.isHidden = true
        }
        
        if let inputItem = self.extensionContext?.inputItems.first as? NSExtensionItem,
            let attachmentsKeys = inputItem.userInfo?[NSExtensionItemAttachmentsKey] as? [NSItemProvider] {
            var itemProvider: NSItemProvider?
            var contentType: String = ""
            
            for item in attachmentsKeys {
                itemProvider = item
                if item.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    contentType = kUTTypeURL as String
                    break
                } else if item.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    contentType = kUTTypeImage as String
                    break
                } else if item.hasItemConformingToTypeIdentifier(kUTTypeMovie as String) {
                    contentType = kUTTypeMovie as String
                    break
                }
            }
            
            if itemProvider == nil {
                return;
            }
            
            itemProvider!.loadItem(forTypeIdentifier: contentType, options: nil, completionHandler: {(result, error) in
                if error == nil {
                    self.performSelector(onMainThread: #selector(self.processResult(_:)), with: ["data": result!, "contentType": contentType], waitUntilDone: false)
                } else {
                    let errorAlert = UIAlertController(title: "", message: "Error occured when grab url.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default) {action in
                        
                    })
                    self.present(errorAlert, animated: true)
                }
            })
        }
        
        // TapGestureRecognizer
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    func processResult(_ result: Any) -> Void {
        let result = result as! [String: Any]
        let data = result["data"]
        let contentType = result["contentType"] as! String
        let url = data as! URL
        
        DispatchQueue.main.async {
            if contentType == kUTTypeURL as String {
                self.shareView.isHidden = false
                self.urlTextField.text = url.absoluteString
            } else if contentType == kUTTypeImage as String {
                self.uploadView.isHidden = false
                self.imgPreview.isHidden = false
                self.videoPreview.isHidden = true
                do {
                    let fileData = try Data(contentsOf: url as URL)
                    self.fileURL = url
                    self.mediaType = "image"
                    self.imgPreview.image = UIImage(data: fileData)
                    self.imgPreview.contentMode = .scaleAspectFit
                } catch (let error) {
                    print("error print", error.localizedDescription)
                }
            } else if contentType == kUTTypeMovie as String {
                self.uploadView.isHidden = false
                self.imgPreview.isHidden = true
                self.videoPreview.isHidden = false
                
                self.fileURL = url
                self.mediaType = "video"
                let videoPlayer = AVPlayer(url: url as URL)
                let playerLayer = AVPlayerLayer(player: videoPlayer)
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.videoPreview.layer.addSublayer(playerLayer)
                playerLayer.frame = self.videoPreview.layer.bounds
                videoPlayer.play()
                
            }
        }
    }
    
    private func clearFields() -> Void {
        txtTitle.text = ""
        txtDescription.text = ""
        txtSubjectTags.text = ""
        fileURL = nil
        fileData = nil
        imgPreview.image = nil
        imgPreview.isHidden = true
        videoPreview.isHidden = true
    }
    
    private func validateFields() -> Bool {
        if txtTitle.text == "" {
            WMGlobal.showAlert(title: "Title is required", message: "", target: self)
            return false
        } else if txtDescription.text == "" {
            WMGlobal.showAlert(title: "Description is required", message: "", target: self)
            return false
        } else if txtSubjectTags.text == "" {
            WMGlobal.showAlert(title: "Subject Tags is required", message: "", target: self)
            return false
        } else if fileURL == nil {
            WMGlobal.showAlert(title: "You need to attach photo or video", message: "", target: self)
            return false
        }
        
        return true
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //- MARK: Actions
    @IBAction func _onOK(_ sender: Any) {
        let savePageViewController = self.storyboard?.instantiateViewController(withIdentifier: "SavePageViewController") as! SavePageViewController
        savePageViewController.url = self.serverURLForSavePage + self.urlTextField.text!
        
        if btnCheck.isSelected {
            savePageViewController.saveToMyWebArchive = true
        }
        
        if WMGlobal.isLoggedIn(), let userData = WMGlobal.getUserData() {
            WMAPIManager
                .sharedManager
                .getCookieData(email: userData["email"] as! String,
                            password: userData["password"] as! String,
                            completion: { (cookieData) in
                                
                let loggedInSig = cookieData["logged-in-sig"] as! HTTPCookie
                let loggedInUser = cookieData["logged-in-user"] as! HTTPCookie
                var tmpData = userData
                                                        
                tmpData["logged-in-sig"] = loggedInSig
                tmpData["logged-in-user"] = loggedInUser
                WMGlobal.saveUserData(userData: tmpData)
                                                        
                DispatchQueue.main.async {
                    self.present(savePageViewController, animated: true, completion: nil)
                }
                                
            })
        } else {
            DispatchQueue.main.async {
                self.present(savePageViewController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func _onCancel(_ sender: Any) {
        exit(0)
    }
    
    @IBAction func onPressedCheck(_ sender: Any) {
        btnCheck.isSelected = !btnCheck.isSelected
    }
    
    @IBAction func _onUpload(_ sender: Any) {
        if !validateFields() {
            return
        }
        
        let userData = WMGlobal.getUserData()
        let identifier = "\(userData!["screenname"] as! String)_\(String(format: "%d", Int(NSDate().timeIntervalSince1970)))"
        let s3accesskey = userData!["s3accesskey"]!
        let s3secretkey = userData!["s3secretkey"]!
        let title = txtTitle.text
        let description = txtDescription.text
        let subjectTags = txtSubjectTags.text
        let filename = "\(identifier).\(fileURL!.pathExtension)"
        let startTime = Date()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        WMAPIManager.sharedManager.SendDataToBucket(params: [
            "identifier" : identifier,
            "title": title,
            "description": description,
            "tags": subjectTags,
            "filename" : filename,
            "mediatype" : mediaType,
            "s3accesskey" : s3accesskey,
            "s3secretkey" : s3secretkey,
            "data" : (fileData != nil) ? fileData : fileURL
        ]) { (success, uploadedFileSize) in
            let endTime = Date()
            let interval = endTime.timeIntervalSince(startTime)
            
            let dcf = DateComponentsFormatter()
            dcf.allowedUnits = [.minute, .second]
            dcf.unitsStyle = .brief
            let duration = dcf.string(from: TimeInterval(interval))!
            
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useMB]
            bcf.countStyle = .file
            let filesize = bcf.string(fromByteCount: uploadedFileSize)
            
            self.clearFields()
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if success {
                self.showSuccessAlert(filesize: filesize, duration: duration, uploadedURL: "https://archive.org/details/\(identifier)")
            } else {
                let alertController = UIAlertController(title: "Uploading failed", message: "", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
                    exit(0)
                })
                self.present(alertController, animated: true)
            }
        }
    }
    
    func showSuccessAlert(filesize: String, duration: String, uploadedURL: String) -> Void {
        let alert = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: .alert)
        let customViewWidth: CGFloat = 270
        let viewRect = CGRect(x:0, y:0, width: customViewWidth, height: 250)
        let customView = UIView(frame: viewRect)
        customView.layer.cornerRadius = 20.0
        customView.clipsToBounds = true
        
        let titleRect = CGRect(x: 13.0, y: 17.0, width: customViewWidth - 26, height: 40)
        let titleLabel = UILabel(frame: titleRect)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.text = "Upload successful"
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: customViewWidth/2, y: titleLabel.frame.size.height/2 + 17.0)
        customView.addSubview(titleLabel)
        
        let message = "Uploaded \(filesize) \nIn \(duration) \n\nAvailable here \(uploadedURL)"
        var txtMessageRect = CGRect(x: 13.0, y: 67, width: customViewWidth - 26, height: 200)
        
        let txtMessageContent = UITextView(frame: txtMessageRect)
        txtMessageContent.font = UIFont.systemFont(ofSize: 15.0)
        txtMessageContent.textAlignment = .center
        txtMessageContent.isEditable = false
        txtMessageContent.dataDetectorTypes = [
            .address,
            .link,
            .phoneNumber
        ]
        
        txtMessageContent.delegate = self
        txtMessageContent.text = message
        txtMessageContent.sizeToFit()
        txtMessageRect.size.height = txtMessageContent.frame.height
        txtMessageContent.frame = txtMessageRect
        
        customView.addSubview(txtMessageContent)
        customView.frame.size.height = txtMessageRect.maxY + 20
        
        alert.view.addSubview(customView)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) {action in
            exit(0)
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if scrollView.contentInset.bottom == 0 {
                scrollView.contentInset.bottom = keyboardSize.height
                scrollView.contentOffset.y = keyboardSize.height
            }
            
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if scrollView.contentInset.bottom > 0 {
            scrollView.contentInset.bottom = 0
            scrollView.contentOffset.y = 0
        }
    }
}

extension ShareViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let savePageVC = self.storyboard?.instantiateViewController(withIdentifier: "SavePageViewController") as! SavePageViewController
        savePageVC.url = URL.absoluteString
        dismiss(animated: true, completion: {
            self.present(savePageVC, animated: true, completion: nil)
        })
        return false
    }
}
