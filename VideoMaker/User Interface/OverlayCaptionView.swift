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

protocol OverlayCaptionViewDelegate {
    func keyboardReturnWithEmptyString()
}

class OverlayCaptionView: UIView {
    var textField: UITextField!
    var isFrameSet: Bool = false
    var viewPercentageYPos: CGFloat = 0.0
    var screenToCaptionHeightRatio: CGFloat = 0.0
    var delegate: OverlayCaptionViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textField = UITextField()
        textField.delegate = self
        textField.text = "hi bruh"
        textField.textColor = UIColor.whiteColor()
        textField.font = UIFont.boldSystemFontOfSize(30)
        textField.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        textField.textAlignment = .Center
        addSubview(textField)
    }
    
    required init (coder aDecoder: NSCoder) {
        fatalError("This class doesn't support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isFrameSet {
            textField.sizeToFit()
            textField.frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: textField.frame.size.height)
            screenToCaptionHeightRatio = frame.size.height / textField.frame.size.height
            let frameHeight = frame.size.height
            frame = CGRect(x: 0.0, y: (frame.size.height - textField.frame.size.height) / 2, width: textField.frame.size.width, height: textField.frame.size.height)
            viewPercentageYPos = frame.origin.y / frameHeight
            isFrameSet = true
        } else {
            textField.frame = CGRect(x: 0.0, y: frame.size.height * viewPercentageYPos, width: frame.size.width, height: frame.size.height / screenToCaptionHeightRatio)
            textField.font = fontToFitHeight(30, maxFontSize: 70, labelText: textField.text!, font: textField.font!)
        }
        print("layoutSubviews")
    }
    
    
    private func fontToFitHeight(minFontSize: CGFloat, maxFontSize: CGFloat, labelText: String, font: UIFont) -> UIFont {
        var minFontSize = minFontSize
        var maxFontSize = maxFontSize
        var fontSizeAverage: CGFloat = 0
        var textAndLabelHeightDiff: CGFloat = 0
        let font = font
    
        while (minFontSize <= maxFontSize) {
            fontSizeAverage = minFontSize + (maxFontSize - minFontSize) / 2
            
            let labelHeight = frame.size.height
            let testStringHeight = labelText.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSizeAverage)]).height
            textAndLabelHeightDiff = labelHeight - testStringHeight
    
            if (fontSizeAverage == minFontSize || fontSizeAverage == maxFontSize) {
                if (textAndLabelHeightDiff < 0) {
                    return font.fontWithSize(fontSizeAverage - 1)
                }
                return font.fontWithSize(fontSizeAverage)
            }
            
            if (textAndLabelHeightDiff < 0) {
                maxFontSize = fontSizeAverage - 1
                
            } else if (textAndLabelHeightDiff > 0) {
                minFontSize = fontSizeAverage + 1
                
            } else {
                return font.fontWithSize(fontSizeAverage)
            }
        }

        return font.fontWithSize(fontSizeAverage)
    }
}

extension OverlayCaptionView: SCVideoOverlay {
    func updateWithVideoTime(time: NSTimeInterval) {
        print("updatewithVideoTime, time: \(time)")
    }
}

extension OverlayCaptionView: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string) as NSString
        let textSize = newString.sizeWithAttributes([NSFontAttributeName : textField.font!])
        return (textSize.width < textField.bounds.size.width) ? true : false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if textField.text == "" {
            delegate?.keyboardReturnWithEmptyString()
        }
        return true
    }
}