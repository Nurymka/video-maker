//
//  AppearanceKit.swift
//  VideoMaker
//
//  Created by Tom on 10/22/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

// for custom UIAlertController fonts: http://stackoverflow.com/a/30463812
extension UILabel {
    func setAppearanceFontForAlertController(font: UIFont?) {
        if tag == 1001 {
            return
        }
        
        let isBold = (self.font.fontDescriptor().symbolicTraits.rawValue & UIFontDescriptorSymbolicTraits.TraitBold.rawValue) > 0
        let colors = CGColorGetComponents(textColor.CGColor)
        
        if (self.font.pointSize == 13 && isBold) {
            // set font for UIAlertController title
            self.font = FontKit.alertControllerTitle
        } else if (self.font.pointSize == 13) {
            // set font for UIAlertController message
            self.font = FontKit.alertControllerMessage
        } else if (isBold) {
            // set font for UIAlertAction with UIAlertActionStyleCancel
            self.font = FontKit.alertControllerCancel
        } else if (colors[0] == 1) {
            // set font for UIAlertAction with UIAlertActionStyleDestructive
            self.font = FontKit.alertControllerDestructive
        } else {
            // set font for UIAlertAction with UIAlertActionStyleDefault
            self.font = FontKit.alertControllerDefault
        }
        
        tag = 1001
    }
}
