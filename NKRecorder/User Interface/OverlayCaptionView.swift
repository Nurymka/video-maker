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

class OverlayCaptionView: UITextField {
    var viewPercentageYPos: CGFloat = 0.0
    var screenToCaptionHeightRatio: CGFloat = 0.0
    var overlayViewDelegate: OverlayCaptionViewDelegate?
    
    init(superviewFrame: CGRect) {
        super.init(frame: CGRectZero)
        delegate = self
        text = "my caption"
        textColor = UIColor.whiteColor()
        font = FontKit.captionFont
        backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        textAlignment = .Center
        sizeToFit()
        frame = CGRect(x: 0, y: (superviewFrame.size.height - frame.size.height) / 2, width: superviewFrame.size.width, height: frame.size.height)
        screenToCaptionHeightRatio = superviewFrame.size.height / frame.size.height
        viewPercentageYPos = frame.origin.y / superviewFrame.size.height
        print(frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print(frame.size.width)
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
    
    func copyWithNSCoder() -> OverlayCaptionView {
        return NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(self)) as! OverlayCaptionView
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
            overlayViewDelegate?.keyboardReturnWithEmptyString()
        }
        return true
    }
}