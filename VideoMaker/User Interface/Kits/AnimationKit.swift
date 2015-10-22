//
//  AnimationKit.swift
//  VideoMaker
//
//  Created by Tom on 10/18/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

class AnimationKit {
    static func fadeIn() -> CAAnimation {
        let fadeInAnim = CABasicAnimation(keyPath: "opacity")
        fadeInAnim.duration = 0.2
        fadeInAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        fadeInAnim.fromValue = NSNumber(float: 0.0)
        fadeInAnim.toValue = NSNumber(float: 1.0)
        return fadeInAnim
    }
    
    static func fadeOut() -> CAAnimation {
        let fadeOutAnim = CABasicAnimation(keyPath: "opacity")
        fadeOutAnim.duration = 0.2
        fadeOutAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        fadeOutAnim.fromValue = NSNumber(float: 1.0)
        fadeOutAnim.toValue = NSNumber(float: 0.0)
        return fadeOutAnim
    }
}
