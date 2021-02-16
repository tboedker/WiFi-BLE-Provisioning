//
//  GeniView.swift
//  BLETool
//
//  Created by Thomas Bødker on 04/07/2017.
//  Copyright © 2017 iOS_Developer01. All rights reserved.
//

import UIKit

protocol DeviceViewDelegate: class {
    
    func deviceSetup(SSID: String, Password: String)
    
}


class DeviceView: UIView, UITextViewDelegate, UITextFieldDelegate {
    
    weak var delegate: DeviceViewDelegate?

    @IBOutlet var view: UIView!
    
    @IBOutlet var txtSSID: UITextField!
    @IBOutlet var txtPassword: UITextField!
    
    @IBOutlet var btnSend: UIButton!
    @IBOutlet var btnCancel: UIButton!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    
    func initSubviews() {
        
         let view = Bundle.main.loadNibNamed("DeviceView", owner: self, options: nil)![0] as! UIView
         self.addSubview(view)
         view.frame = self.bounds
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))

        self.view.addGestureRecognizer(tap)
        
    }
    
    override func layoutSubviews() {
       
       // lblSampleTime.text = "Sample time (\(UInt16(sldrSampleTime.value)) ms)"
        self.txtSSID.delegate? = self
        txtPassword.isSecureTextEntry = true
    }
    
    
    @IBAction func btnCancelTapped(_ sender: Any) {
        
        self.delegate?.deviceSetup(SSID: "", Password: "")
        
        hideKeyBoard()
        self.removeFromSuperview()
    }
    
    @IBAction func btnSendTapped(_ sender: Any) {
        

        self.delegate?.deviceSetup(SSID:txtSSID.text!, Password:txtPassword.text!)
            
            hideKeyBoard()
        
            self.removeFromSuperview()
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyBoard()
        return true
    }
    
    @objc func hideKeyBoard()  {
        txtSSID.resignFirstResponder()
        txtPassword.resignFirstResponder()
    }
  
    

}


