//
//  TrackNameLabel.swift
//  VideoMaker
//
//  Created by Tom on 10/19/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

class TrackNameLabel: UILabel {
    private var scrollTimer: NSTimer?
    
    func changeScrollableTextTo(string: String) {
        text = string
        if isTruncated() {
            text = string + "           "
            scrollTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "scrollLabel", userInfo: nil, repeats: true)
        } else {
            scrollTimer?.invalidate()
        }
    }
    
    func scrollLabel() {
        let curString = text! as NSString
        text = curString.substringFromIndex(1) + curString.substringToIndex(1)
    }
}

extension UILabel {
    func isTruncated() -> Bool {
        if let string = self.text {
            let size: CGSize = (string as NSString).boundingRectWithSize(CGSize(width: self.frame.size.width, height: 999999.0), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: self.font], context: nil).size
            
            if (size.height > self.bounds.size.height) {
                return true
            }
        }
        
        return false
    }
}
