//
//  OverlayCaptionView.swift
//  VideoMaker
//
//  Created by Tom on 9/11/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import Foundation
import UIKit
import SCRecorder

class OverlayCaptionView: UIView {
    var captionTextField: UITextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        captionTextField = UITextField()
        captionTextField.delegate = self
        captionTextField.text = "hi bruh"
        captionTextField.textColor = UIColor.whiteColor()
        captionTextField.font = UIFont.boldSystemFontOfSize(30)
        captionTextField.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        captionTextField.textAlignment = .Center
        addSubview(captionTextField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        captionTextField.sizeToFit()
        let x = CGFloat(0.0)
        let y = CGFloat((frame.size.height - captionTextField.frame.size.height) / 2)
        let width = frame.size.width
        captionTextField.frame = CGRect(x: x, y: y, width: width, height: captionTextField.frame.size.height)
    }
    
    required init (coder aDecoder: NSCoder) {
        fatalError("This class doesn't support NSCoding")
    }
}

extension OverlayCaptionView: SCVideoOverlay {
    func updateWithVideoTime(time: NSTimeInterval) {
        println("updatewithVideoTime, time: \(time)")
    }
}

extension OverlayCaptionView: UITextFieldDelegate {
    /*
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
    }*/
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        captionTextField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        
        return true
    }
}